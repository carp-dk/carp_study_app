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

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async => status;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    requestCount++;
    status = PermissionStatus.granted;
    return {for (final p in permissions) p: status};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const backgroundChannel = MethodChannel('flutter_background');
  late _FakePermissions permissions;
  late List<String> backgroundCalls;

  setUp(() async {
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
    // Reset the singleton, which outlives each test.
    await BackgroundSensingService().refresh();
  });

  tearDown(() {
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

    test('is not supported off Android, so it never starts the service', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await BackgroundSensingService().connect();

      expect(permissions.requestCount, 0);
      expect(BackgroundSensingService().isConnected, isFalse);
    });
  });
}
