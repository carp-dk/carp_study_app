// End-to-end test of the join-study flow in LOCAL deployment mode, using the
// study in assets/carp: sign in, accept the invitation, sign consent,
// configure the study and start sensing.
//
// Run on a simulator or device with:
//
//   flutter test integration_test
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:research_package/research_package.dart';

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

  // Granted battery exemption makes background sensing start, and the real
  // plugin then opens the "Stop optimizing battery usage" system dialog.
  messenger.setMockMethodCallHandler(const MethodChannel('flutter_background'), (call) async => true);

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
    'homePage=${find.byType(HomePage).evaluate().isNotEmpty}';

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
      AppConfig.deploymentMode = DeploymentMode.local;
      AppConfig.debugLevel = DebugLevel.debug;

      mockSimulatorPlatformChannels();

      // Same package initialization as main().
      CarpMobileSensing.ensureInitialized();
      CognitionPackage.ensureInitialized();
      CarpDataManager.ensureInitialized();

      // The same steps the screens take, against the study in assets/carp:
      // sign in -> the one invitation -> accept -> sign consent -> study runs.
      await Settings().init();
      await bloc.initialize();
      await tester.pumpWidget(const CarpStudyApp());
      await pumpUntil(tester, () => find.byType(LoginPage).evaluate().isNotEmpty, reason: 'login page');

      await bloc.auth.authenticate();
      final invitations = bloc.appViewModel.invitationsListViewModel;
      await invitations.loadInvitations();
      expect(invitations.invitations, hasLength(1));
      invitations.accept(invitations.invitations.single);
      expect(bloc.study.hasStudy, isTrue);

      // Consent is signed through the backend, as on CAWS - kept in memory locally.
      final consent = bloc.appViewModel.informedConsentViewModel;
      final document = await consent.getInformedConsent();
      await consent.accept(
        RPTaskResult(identifier: 'consent')
          ..results['signature'] = RPConsentSignatureResult(
            identifier: 'signature',
            consentDocument: RPConsentDocument(title: document?.identifier ?? 'Consent', sections: []),
            signature: RPSignatureResult(firstName: 'Integration', signatureImage: 'png'),
          ),
      );
      expect(await bloc.consent.hasSignedConsent(bloc.study.study), isTrue);
      // Leave the login page as it does after sign-in; the router takes it from there.
      GoRouter.of(tester.element(find.byType(LoginPage))).go(CarpAppState.homeRoute);

      await pumpUntil(tester, () => bloc.isConfigured, reason: 'study configuration to complete');
      expect(bloc.study.isDeployed, isTrue);

      // Sensing must actually have been started - the executor is resumed.
      await pumpUntil(tester, () => bloc.study.isRunning, reason: 'sensing to start');

      // And the user lands on the home page.
      await pumpUntil(tester, () => find.byType(HomePage).evaluate().isNotEmpty, reason: 'home page to be shown');

      final study = bloc.study.study!;
      bool isOurs(String? deploymentId) => deploymentId == study.studyDeploymentId;
      Future<bool> persistedTasks() async =>
          (await PersistenceService().getUserTasks()).any((t) => isOurs(t.studyDeploymentId));
      expect(await PersistenceService().getStudy(study.studyDeploymentId, study.deviceRoleName), isNotNull);
      expect(SmartPhoneClientManager().studies, contains(study));

      // Profile -> Sign Out -> confirm, as the user does it.
      await tester.tap(find.byTooltip('Profile'));
      await pumpUntil(tester, () => find.byType(ProfilePage).evaluate().isNotEmpty, reason: 'profile page');
      await tester.scrollUntilVisible(find.byIcon(Icons.power_settings_new), 300);
      await tester.tap(find.byIcon(Icons.power_settings_new));
      await pumpUntil(tester, () => find.byType(AlertDialog).evaluate().isNotEmpty, reason: 'sign out confirmation');
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton)).last);
      await pumpUntil(
        tester,
        () => find.byType(LoginPage).evaluate().isNotEmpty,
        reason: 'login page after signing out',
      );

      // Back to the initial state, with nothing of the study left on the phone.
      expect(bloc.state, AppState.initialized);
      expect(bloc.auth.isAuthenticated, isFalse);
      expect(bloc.study.hasStudy, isFalse);
      expect(bloc.study.isRunning, isFalse);
      expect(BackgroundSensingService().isConnected, isFalse);
      expect(LocalSettings().study, isNull);
      expect(LocalSettings().participant, isNull);
      expect(SmartPhoneClientManager().studies, isNot(contains(study)));
      expect(
        AppTaskController().userTasks.where((t) => isOurs(t.appTaskExecutor.deployment?.studyDeploymentId)),
        isEmpty,
      );
      expect(await PersistenceService().getStudy(study.studyDeploymentId, study.deviceRoleName), isNull);
      expect(await bloc.consent.hasSignedConsent(study), isFalse);
      // Dequeued tasks are deleted from the database asynchronously.
      for (var i = 0; i < 20 && await persistedTasks(); i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(await persistedTasks(), isFalse);
    },
  );
}
