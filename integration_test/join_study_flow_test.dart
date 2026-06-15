// End-to-end test of the join-study flow in LOCAL deployment mode:
// deploy a protocol locally, gate on informed consent, configure the study
// (Sensing initialize -> addStudy -> tryDeployment -> verify deployed), and
// start sensing.
//
// Run on a simulator or device with:
//
//   flutter test integration_test --dart-define=deployment-mode=local
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:carp_study_app/main.dart';

/// Mock the platform channels a simulator cannot serve: OS permission
/// dialogs (which a test cannot answer) and battery hardware (which a
/// simulator does not have). Everything else - deployment, sensing runtime,
/// routing, consent - runs for real.
void mockSimulatorPlatformChannels() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async {
    const granted = 1;
    switch (call.method) {
      case 'requestPermissions':
        return {for (final permission in (call.arguments as List).cast<int>()) permission: granted};
      case 'checkPermissionStatus':
      case 'checkServiceStatus':
        return granted;
      default:
        return null;
    }
  });

  messenger.setMockMethodCallHandler(const MethodChannel('dexterous.com/flutter/local_notifications'), (call) async {
    switch (call.method) {
      case 'initialize':
      case 'requestPermissions':
        return true;
      case 'pendingNotificationRequests':
        return <Map<String, Object?>>[];
      default:
        return null;
    }
  });

  messenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/battery'), (call) async {
    switch (call.method) {
      case 'getBatteryLevel':
        return 100;
      case 'getBatteryState':
        return 'full';
      case 'isInBatterySaveMode':
        return false;
      default:
        return null;
    }
  });

  messenger.setMockStreamHandler(
    const EventChannel('dev.fluttercommunity.plus/charging'),
    MockStreamHandler.inline(onListen: (arguments, events) => events.success('full')),
  );
}

/// Pump frames until [condition] is true. Used instead of [WidgetTester.pumpAndSettle]
/// since loaders with endless animations never settle.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(minutes: 2),
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  var lastDump = DateTime.now();
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('pumpUntil timed out${reason != null ? ' waiting for: $reason' : ''} - ${_diagnostics()}');
    }
    if (DateTime.now().difference(lastDump) > const Duration(seconds: 5)) {
      lastDump = DateTime.now();
      debugPrint('pumpUntil${reason != null ? ' [$reason]' : ''} - ${_diagnostics()}');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
}

String _diagnostics() =>
    'bloc.state=${bloc.state}, hasStudy=${bloc.study.hasStudy}, isDeployed=${bloc.study.isDeployed}, '
    'isRunning=${bloc.study.isRunning}, '
    'consentPage=${find.byType(InformedConsentPage).evaluate().isNotEmpty}, '
    'studyPage=${find.byType(StudyPage).evaluate().isNotEmpty}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Stop the study after the test so the bloc's periodic timers (message
  // polling, view-model persistence) and the user-task subscription are
  // cancelled - otherwise the isolate never goes idle and the run hangs
  // after "All tests passed!". Also clears the persisted study so the next
  // run starts clean.
  tearDown(() async {
    try {
      await bloc.leaveStudy();
    } catch (_) {
      // best-effort cleanup - never mask the test result
    }
  });

  testWidgets(
    'join study flow: deploy, consent gate, configure, start sensing',
    timeout: const Timeout(Duration(minutes: 5)),
    (tester) async {
      // This exercises the local-mode join flow, so force local deployment and
      // debug logging regardless of how the suite is launched - otherwise a run
      // without --dart-define=deployment-mode=local defaults to production and
      // the test would silently skip. Set before bloc.initialize() reads them.
      AppConfig().deploymentMode = DeploymentMode.local;
      AppConfig().debugLevel = DebugLevel.debug;

      mockSimulatorPlatformChannels();

      // Same package initialization as main().
      CarpMobileSensing.ensureInitialized();
      CognitionPackage.ensureInitialized();
      CarpDataManager.ensureInitialized();

      // Deploy a minimal study protocol on the local (on-phone) deployment
      // service - the in-test equivalent of placing a protocol.json in
      // assets/carp/resources/ for local mode.
      await Settings().init();
      final phone = Smartphone();
      final protocol = SmartphoneStudyProtocol(name: 'Join flow integration test', ownerId: 'test')
        ..addPrimaryDevice(phone)
        ..addTaskControl(
          ImmediateTrigger(),
          BackgroundTask(measures: [Measure(type: DeviceSamplingPackage.BATTERY_STATE)]),
          phone,
        );
      final status = await SmartphoneDeploymentService().createStudyDeployment(protocol);
      final primaryDeviceRoleName = status.deviceStatusList
          .firstWhere((deviceStatus) => deviceStatus.device is PrimaryDeviceConfiguration)
          .device
          .roleName;
      LocalSettings().participant = Participant(
        studyDeploymentId: status.studyDeploymentId,
        deviceRoleName: primaryDeviceRoleName,
      );
      bloc.study.study = SmartphoneStudy(
        studyDeploymentId: status.studyDeploymentId,
        deviceRoleName: primaryDeviceRoleName,
      );

      await bloc.initialize();

      // The study descriptor exists, but it is not deployed in the sensing
      // runtime and consent has not been given yet.
      expect(bloc.study.hasStudy, isTrue);
      expect(bloc.study.isDeployed, isFalse);
      expect(await bloc.consent.hasBeenAccepted, isFalse);

      await tester.pumpWidget(const CarpStudyApp());

      // The home page must gate on consent before configuring the study. With
      // no local consent document, the consent page auto-accepts, which lets
      // setup proceed: configure -> deploy -> verify -> start.
      await pumpUntil(
        tester,
        () => LocalSettings().participant?.hasInformedConsentBeenAccepted ?? false,
        reason: 'consent gate to accept',
      );
      await pumpUntil(tester, () => bloc.isConfigured, reason: 'study configuration to complete');

      expect(await bloc.consent.hasBeenAccepted, isTrue);
      expect(bloc.study.isDeployed, isTrue);
      expect(bloc.study.deployment?.studyDeploymentId, status.studyDeploymentId);

      // Sensing must actually have been started - the executor is resumed.
      await pumpUntil(tester, () => bloc.study.isRunning, reason: 'sensing to start');

      // And the user lands on the study page.
      await pumpUntil(tester, () => find.byType(StudyPage).evaluate().isNotEmpty, reason: 'study page to be shown');

      // Signing out tears down sensing, clears auth, erases the study, and
      // returns to the initial state - the router sends the user back to the
      // invitation flow.
      await bloc.signOutAndLeaveStudy();

      expect(bloc.state, StudyAppState.initialized);
      expect(bloc.study.hasStudy, isFalse);
      expect(bloc.study.isRunning, isFalse);
      expect(bloc.auth.isAuthenticated, isFalse);

      await pumpUntil(
        tester,
        () => find.byType(InvitationListPage).evaluate().isNotEmpty,
        reason: 'invitation list after signing out',
      );
    },
  );
}
