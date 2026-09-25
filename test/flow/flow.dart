import 'dart:convert';
import 'dart:io';

import 'package:carp_backend/carp_backend.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signature/signature.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../exports.dart';
import '../test_utils.dart';

/// Warnings the host causes - it has no sensors, devices or OS services - plus
/// known CAMS noise. Any other warning fails the flow.
const _expectedWarnings = [
  'Initialize DeviceInfo before creating a Smartphone registration',
  'Local protocol is trying to use a non-local data endpoint',
  'This may be because this probe is not available',
  'is not connected. Cannot resume sampling',
  'BackgroundService - ',
  'HealthServiceManager has not the permissions required',
  'Could not get location',
  // CAMS: a local deployment cannot unregister devices, and the Flanker ->
  // Reaction Time trigger initializes the Reaction Time task a second time.
  'Failed to unregister device',
  'Trying to initialize a AppTaskExecutor',
];

/// The test font's glyphs are wide squares, so text overflows that fits on a phone.
const _testFontErrors = ['A RenderFlex overflowed'];

/// Runs the real app on the host, in local deployment mode with the CARP Test
/// Study, against a fake phone that grants everything. What happens is
/// recorded in [Flow.events], printed when the test fails.
///
/// ponytail: one flowTest per file - the bloc and CAMS are process-wide
/// singletons. Resetting them would allow several per file.
void flowTest(String description, Future<void> Function(WidgetTester tester, Flow flow) body) {
  testWidgets(description, (tester) async {
    final flow = Flow._(tester);
    final onError = FlutterError.onError!;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      flow.events.add('error ${message.split('\n').first}');
      if (!_testFontErrors.any(message.contains)) onError(details);
    };
    try {
      await flow._start();
      await body(tester, flow);
    } catch (_) {
      final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).nonNulls;
      debugPrint('On screen: ${texts.join(' | ')}');
      rethrow;
    } finally {
      FlutterError.onError = onError;
      printOnFailure('Flow events:\n  ${flow.events.join('\n  ')}');
      await flow._stop();
    }
    final unexpected = flow.events.where((e) => e.startsWith('warning') && !_expectedWarnings.any(e.contains));
    expect(unexpected, isEmpty, reason: 'unexpected warnings');
  });
}

class Flow {
  Flow._(this.tester);

  final WidgetTester tester;

  /// In order: `app <AppState>`, `route <location>`, `task <name> <UserTaskState>`,
  /// `permission <Permission>` (each asked for), `warning <CAMS warning>`, `error <Flutter error>`.
  final events = <String>[];

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _cwd = Directory.current;
  final _debugPrint = debugPrint;
  GoRouter? _router;

  List<String> get permissions => [
    for (final e in events)
      if (e.startsWith('permission ')) e.substring(11),
  ];

  /// Pumps until [condition] holds, letting real I/O (SQLite, files) progress.
  Future<void> pumpUntil(bool Function() condition, String reason) async {
    for (var i = 0; i < 300; i++) {
      if (condition()) return;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('Timed out waiting for $reason');
  }

  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Reads through, agrees to, signs and finishes the consent document.
  Future<void> signConsent() async {
    await pumpUntil(() => find.text('NEXT').evaluate().isNotEmpty, 'the consent document');
    for (var page = 0; find.text('SEE SUMMARY').evaluate().isEmpty; page++) {
      if (page > 50) fail('Consent never reached its summary');
      await tap(find.text('NEXT'));
    }
    await tap(find.text('SEE SUMMARY'));
    await tap(find.text('AGREE'));
    await tap(find.text('AGREE').last); // the confirmation dialog
    await tester.enterText(find.byType(TextFormField).first, 'Test');
    await tester.enterText(find.byType(TextFormField).last, 'Participant');
    await tester.drag(find.byType(Signature), const Offset(120, 30));
    await tester.pump();
    await tester.tap(find.text('NEXT'));
    // The signature image encodes asynchronously - on a phone before the next frame
    // removes the step. Pumping first sets state on the gone step, dropping the signature.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    await tap(find.text('DONE'));
  }

  Future<void> _start() async {
    tester.view.physicalSize = const Size(1170, 2532); // an iPhone screen
    tester.view.devicePixelRatio = 3;
    final fixtures = '${_cwd.path}/test/flow/fixtures/test_study';
    // mobility_features stores its data in ./test/testdata when not on a phone.
    Directory.current = Directory.systemTemp.createTempSync('flow');
    Directory('test/testdata').createSync(recursive: true);

    tester.binding.defaultBinaryMessenger.allMessagesHandler = (channel, handler, message) {
      if (channel == 'flutter/assets') {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key.startsWith('assets/carp/')) {
          return Future.value(ByteData.sublistView(File('$fixtures/${key.split('/').last}').readAsBytesSync()));
        }
      }
      if (handler != null) return handler(message);
      const codec = StandardMethodCodec();
      final MethodCall call;
      try {
        call = codec.decodeMethodCall(message);
      } on Object {
        return null; // not a standard method call, e.g. flutter/platform
      }
      if (call.method == 'requestPermissions') {
        events.addAll([for (final p in call.arguments as List) 'permission ${Permission.byValue(p as int)}']);
      }
      return Future.value(codec.encodeSuccessEnvelope(_phone(channel, call)));
    };

    debugPrint = (message, {wrapWidth}) {
      if (message != null && message.contains('[CAMS WARNING]')) {
        events.add('warning ${message.split('\x1B[0m ').last}');
      }
      _debugPrint(message, wrapWidth: wrapWidth);
    };
    bloc.addListener(_onApp);
    _subscriptions.add(AppTaskController().userTaskEvents.listen(_onTask));

    await tester.runAsync(() async {
      // Plugins register with the engine, which the host has none of.
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
      await databaseFactory.setDatabasesPath(Directory.current.path);
      await initTestSettings();
      AppConfig.deploymentMode = DeploymentMode.local;
      AppConfig.debugLevel = DebugLevel.warning;
      CarpMobileSensing.ensureInitialized();
      CognitionPackage.ensureInitialized();
      CarpDataManager.ensureInitialized();
      await bloc.initialize();
      // CAMS singletons own process-wide timers - start them outside the fake clock.
      await Sensing().initialize(bloc.study.deploymentService);
    });

    await tester.pumpWidget(const CarpStudyApp());
    _router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
    _router!.routerDelegate.addListener(_onRoute);
    _onRoute();
  }

  Future<void> _stop() async {
    await tester.runAsync(() => bloc.leaveStudy().timeout(const Duration(seconds: 10)));
    await tester.pump(const Duration(minutes: 1));
    tester.view.reset();
    AppTaskController().dispose(); // its hourly expiry timer outlives the study
    // Cancelling completes on the real event loop - awaited outside runAsync, the test never ends.
    await tester.runAsync(() => Future.wait(_subscriptions.map((s) => s.cancel())));
    _router?.routerDelegate.removeListener(_onRoute);
    bloc.removeListener(_onApp);
    debugPrint = _debugPrint;
    tester.binding.defaultBinaryMessenger.allMessagesHandler = null;
    Directory.current = _cwd;
  }

  void _add(String event) {
    if (events.lastOrNull != event) events.add(event);
  }

  void _onApp() => _add('app ${bloc.state.name}');

  void _onRoute() => _add('route ${_router!.routerDelegate.currentConfiguration.uri}');

  void _onTask(UserTask task) {
    _add('task ${task.name} ${task.state.name}');
    _subscriptions.add(task.stateEvents.listen((state) => _add('task ${task.name} ${state.name}')));
  }
}

/// What the fake phone answers - everything is granted, enabled and available.
Object? _phone(String channel, MethodCall call) {
  if (channel == 'flutter.baseflow.com/permissions/methods') {
    return call.method == 'requestPermissions' ? {for (final p in call.arguments as List) p: 1} : 1;
  }
  return switch ('$channel#${call.method}') {
    'flutter_timezone#getLocalTimezone' => 'Europe/Copenhagen',
    'dexterous.com/flutter/local_notifications#initialize' => true,
    'dexterous.com/flutter/local_notifications#pendingNotificationRequests' => <Object>[],
    'dev.fluttercommunity.plus/device_info#getDeviceInfo' => _iPhone,
    'flutter_background#initialize' || 'flutter_background#hasPermissions' => true,
    _ when channel == 'lyokone/location' => 1,
    _ => null,
  };
}

// Plugins take their iOS path on the host, as it is not Android.
const _iPhone = {
  'name': 'Test iPhone',
  'systemName': 'iOS',
  'systemVersion': '18.0',
  'model': 'iPhone',
  'modelName': 'iPhone 16',
  'localizedModel': 'iPhone',
  'identifierForVendor': 'test-device',
  'isPhysicalDevice': false,
  'physicalRamSize': 0,
  'availableRamSize': 0,
  'isiOSAppOnMac': false,
  'isiOSAppOnVision': false,
  'freeDiskSize': 0,
  'totalDiskSize': 0,
  'utsname': {'sysname': 'Darwin', 'nodename': 'test', 'release': '', 'version': '', 'machine': 'iPhone17,3'},
};
