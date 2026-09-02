import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'exports.dart';

/// A [PermissionHandlerPlatform] that reports whatever status it is told to,
/// and grants on request.
class _FakePermissions extends PermissionHandlerPlatform with MockPlatformInterfaceMixin {
  PermissionStatus status = PermissionStatus.denied;
  int requestCount = 0;
  final requested = <Permission>[];

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async => status;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    requestCount++;
    requested.addAll(permissions);
    status = PermissionStatus.granted;
    return {for (final p in permissions) p: status};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const backgroundChannel = MethodChannel('flutter_background');
  late _FakePermissions permissions;
  late List<String> backgroundCalls;

  late PermissionHandlerPlatform originalPermissions;

  setUp(() async {
    originalPermissions = PermissionHandlerPlatform.instance;
    permissions = _FakePermissions();
    PermissionHandlerPlatform.instance = permissions;

    backgroundCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(backgroundChannel, (
      call,
    ) async {
      backgroundCalls.add(call.method);
      return true;
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // Reset the singleton, which outlives each test - and drop the calls the
    // reset itself makes, so each test starts from a clean log.
    await BackgroundSensingService().refresh();
    backgroundCalls.clear();
  });

  tearDown(() {
    PermissionHandlerPlatform.instance = originalPermissions;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(backgroundChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('BackgroundSensingService', () {
    test('is disconnected while the permission is denied', () async {
      await BackgroundSensingService().refresh();

      expect(BackgroundSensingService().isConnected, isFalse);
      expect(backgroundCalls, isEmpty);
    });

    test('connect asks for the permission and starts the foreground service', () async {
      var notifications = 0;
      void listener() => notifications++;
      BackgroundSensingService().addListener(listener);

      await BackgroundSensingService().connect();

      expect(permissions.requestCount, 1);
      expect(BackgroundSensingService().isConnected, isTrue);
      expect(backgroundCalls, contains('enableBackgroundExecution'));
      expect(notifications, 1);

      BackgroundSensingService().removeListener(listener);
    });

    test('a revoked exemption stops the running service', () async {
      await BackgroundSensingService().connect();
      expect(BackgroundSensingService().isConnected, isTrue);

      permissions.status = PermissionStatus.denied;
      await BackgroundSensingService().refresh();

      expect(BackgroundSensingService().isConnected, isFalse);
      expect(backgroundCalls, contains('disableBackgroundExecution'));
    });

    test('disconnect stops the foreground service', () async {
      await BackgroundSensingService().connect();
      expect(BackgroundSensingService().isConnected, isTrue);

      await BackgroundSensingService().disconnect();

      expect(BackgroundSensingService().isConnected, isFalse);
      expect(backgroundCalls, contains('disableBackgroundExecution'));
    });

    test('on iOS connect asks for Always location, and no foreground service exists', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await BackgroundSensingService().refresh();

      await BackgroundSensingService().connect();

      expect(permissions.requested, [Permission.locationAlways]);
      expect(BackgroundSensingService().isConnected, isTrue);
      expect(backgroundCalls, isEmpty);
    });

    test('on iOS a revoked Always location disconnects', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await BackgroundSensingService().connect();
      expect(BackgroundSensingService().isConnected, isTrue);

      permissions.status = PermissionStatus.denied;
      await BackgroundSensingService().refresh();

      expect(BackgroundSensingService().isConnected, isFalse);
    });

    test('is not supported off the phones, so it never starts', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await BackgroundSensingService().connect();

      expect(permissions.requestCount, 0);
      expect(BackgroundSensingService().isConnected, isFalse);
    });
  });
}
