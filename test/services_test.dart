import 'package:carp_backend/carp_backend.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_core/carp_core.dart' as core;
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:fake_async/fake_async.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';
import 'test_utils.dart';
import 'services_test.mocks.dart';

class _FakeMessageManager extends MessageManager {
  List<Message> toReturn = [];
  bool throwOnGet = false;
  int initializeCount = 0;
  int getCount = 0;

  @override
  void initialize() => initializeCount++;

  @override
  Future<Message?> getMessage(String messageId) async => null;

  @override
  Future<List<Message>> getMessages({DateTime? start, DateTime? end, int? count = 20}) async {
    getCount++;
    if (throwOnGet) throw Exception('offline');
    return List.of(toReturn);
  }

  @override
  Future<void> setMessage(Message message) async {}

  @override
  Future<void> deleteMessage(String messageId) async {}

  @override
  Future<void> deleteAllMessages() async {}
}

class _FakeConsentManager extends InformedConsentManager {
  RPOrderedTask? document;
  bool? lastRefresh;

  @override
  RPOrderedTask? get informedConsent => document;

  @override
  Future<RPOrderedTask?> getConsentDocument({bool refresh = false}) async {
    lastRefresh = refresh;
    return document;
  }

  @override
  Future<bool> setConsentDocument(RPOrderedTask informedConsent) async => true;

  @override
  Future<bool> deleteConsentDocument() async => true;
}

@GenerateNiceMocks([
  MockSpec<CarpBackend>(),
  MockSpec<AuthService>(),
  MockSpec<SystemInfoService>(),
  MockSpec<UserTask>(),
  MockSpec<StudyService>(),
])
void main() {
  setUpAll(() async {
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    await initTestSettings();
  });

  setUp(() {
    AppConfig().deploymentMode = DeploymentMode.local;
  });

  group('AppConfig', () {
    test('defaults to production/info when no environment is given', () {
      // The singleton was created without --dart-define values in tests.
      expect(AppConfig(), same(AppConfig()));
      expect(AppConfig().debugLevel, DebugLevel.info);
      expect(AppConfig().localization, isNull);
    });
  });

  group('MessageService', () {
    Message message(String id, DateTime timestamp) => Message(id: id, title: 'message-$id', timestamp: timestamp);

    test('refresh sorts messages newest first and emits the count', () async {
      final manager = _FakeMessageManager()
        ..toReturn = [
          message('old', DateTime(2024, 1, 1)),
          message('new', DateTime(2025, 1, 1)),
          message('mid', DateTime(2024, 6, 1)),
        ];
      final service = MessageService(manager);

      final emitted = expectLater(service.stream, emits(3));
      await service.refresh();
      await emitted;

      expect(service.messages.map((m) => m.id), ['new', 'mid', 'old']);
      expect(service.byId('mid')?.id, 'mid');
      expect(service.byId('unknown'), isNull);
    });

    test('refresh keeps the old list and does not throw when the manager fails', () async {
      final manager = _FakeMessageManager()..toReturn = [message('a', DateTime(2024, 1, 1))];
      final service = MessageService(manager);
      await service.refresh();

      manager.throwOnGet = true;
      await service.refresh();

      expect(service.messages.length, 1);
    });

    test('start polls periodically, is idempotent, and stop cancels the timer', () {
      fakeAsync((async) {
        final manager = _FakeMessageManager();
        final service = MessageService(manager, pollingInterval: const Duration(minutes: 30));

        service.start();
        service.start(); // no duplicate timer
        async.flushMicrotasks();
        expect(manager.initializeCount, 2);
        expect(manager.getCount, 2); // one refresh per start() call

        async.elapse(const Duration(minutes: 61));
        expect(manager.getCount, 4); // two polls from a single timer

        service.stop();
        async.elapse(const Duration(hours: 2));
        expect(manager.getCount, 4);

        service.dispose();
      });
    });

    test('dispose closes the stream and refresh is still safe', () async {
      final service = MessageService(_FakeMessageManager());
      service.dispose();
      await expectLater(service.stream, emitsDone);
      await service.refresh(); // must not throw on the closed controller
    });
  });

  group('AuthService', () {
    late MockCarpBackend backend;
    late AuthService auth;

    setUp(() {
      backend = MockCarpBackend();
      auth = AuthService(backend: backend);
    });

    test('username and friendlyUsername are empty when signed out', () {
      when(backend.user).thenReturn(null);

      expect(auth.user, isNull);
      expect(auth.username, '');
      expect(auth.friendlyUsername, '');
    });

    test('username and friendlyUsername come from the signed-in user', () {
      when(backend.user).thenReturn(CarpUser(username: 'jdoe', id: '42', firstName: 'John'));

      expect(auth.username, 'jdoe');
      expect(auth.friendlyUsername, 'John');
    });

    test('delegates authentication state to the backend', () {
      when(backend.isAuthenticated).thenReturn(true);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.invitations, isEmpty);
    });

    test('getInvitations keeps only invitations assigned to a smartphone', () async {
      ActiveParticipationInvitation invitation(PrimaryDeviceConfiguration? device) {
        final invitation = ActiveParticipationInvitation(
          Participation('dep-1', 'participant-1', AssignedTo()),
          StudyInvitation('Test study'),
        );
        if (device != null) invitation.assignedDevices = [AssignedPrimaryDevice(device: device)];
        return invitation;
      }

      final forPhone = invitation(Smartphone());
      final forOtherDevice = invitation(core.Smartphone(roleName: 'web'));
      final unassigned = invitation(null);
      when(backend.getInvitations()).thenAnswer((_) async => [forPhone, forOtherDevice, unassigned]);

      final invitations = await auth.getInvitations();

      expect(invitations, [forPhone, unassigned]);
      expect(auth.invitations, [forPhone, unassigned]);
    });
  });

  group('ConsentService', () {
    late _FakeConsentManager manager;
    late MockCarpBackend backend;
    late StudyService studyService;
    late ConsentService consent;

    setUp(() {
      manager = _FakeConsentManager();
      backend = MockCarpBackend();
      studyService = StudyService();
      consent = ConsentService(manager, studyService, backend: backend);
    });

    test('getDocument delegates to the consent manager', () async {
      expect(await consent.getDocument(refresh: true), isNull);
      expect(manager.lastRefresh, isTrue);
    });

    test('local mode falls back to the locally stored participant flag', () async {
      LocalSettings().participant = Participant(studyDeploymentId: 'dep-1');
      expect(await consent.hasBeenAccepted, isFalse);

      await consent.accept();
      expect(await consent.hasBeenAccepted, isTrue);
    });

    test('caches the consent status for synchronous reads', () async {
      LocalSettings().participant = Participant(studyDeploymentId: 'dep-cache');

      expect(consent.isAccepted, isNull);
      expect(await consent.refreshStatus(), isFalse);
      expect(consent.isAccepted, isFalse);

      await consent.accept();
      expect(consent.isAccepted, isTrue);

      consent.reset();
      expect(consent.isAccepted, isNull);
    });

    test('accept notifies listeners', () async {
      LocalSettings().participant = Participant(studyDeploymentId: 'dep-1');
      var notified = false;
      consent.addListener(() => notified = true);

      await consent.accept();
      expect(notified, isTrue);
    });

    test('non-local mode asks the backend and is false when it fails', () async {
      LocalSettings().study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      AppConfig().deploymentMode = DeploymentMode.test;
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer((_) async => throw Exception('offline'));

      expect(await consent.hasBeenAccepted, isFalse);
    });

    test('non-local mode is true when the backend has a consent document', () async {
      LocalSettings().study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      AppConfig().deploymentMode = DeploymentMode.test;
      when(
        backend.getInformedConsentByRole('dep-1', null),
      ).thenAnswer((_) async => InformedConsentInput(userId: '42', name: 'jdoe', consent: '{}', signatureImage: ''));

      expect(await consent.hasBeenAccepted, isTrue);
    });
  });

  group('Old-namespace CAWS compatibility', () {
    test('a pre-CAMS-2.x deployment status with CAMS device types deserializes', () {
      Sensing(); // registers the sampling packages and old-namespace device aliases

      // The shape CAWS returns for deployments created before CAMS 2.x -
      // device types are in the old 'dk.cachet.carp.common.application.devices'
      // namespace, while CAMS 2.x registers them as 'dk.carp.cams.devices'.
      final json = {
        '__type': 'dk.cachet.carp.deployments.application.StudyDeploymentStatus.Running',
        'createdOn': '2026-06-10T12:46:37.103476598Z',
        'studyDeploymentId': '3014e5bc-7f79-45e9-afc3-02a38bfc888f',
        'deviceStatusList': [
          {
            '__type': 'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.Deployed',
            'device': {
              '__type': 'dk.cachet.carp.common.application.devices.Smartphone',
              'isPrimaryDevice': true,
              'roleName': 'Primary Phone',
            },
          },
          {
            '__type': 'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.Registered',
            'device': {
              '__type': 'dk.cachet.carp.common.application.devices.LocationService',
              'accuracy': 'balanced',
              'distance': 10,
              'interval': 60000000,
              'roleName': 'Location Service',
              'isOptional': true,
              'defaultSamplingConfiguration': <String, dynamic>{},
            },
            'canBeDeployed': false,
            'remainingDevicesToRegisterToObtainDeployment': <String>[],
            'remainingDevicesToRegisterBeforeDeployment': <String>[],
          },
        ],
        'participantStatusList': <Map<String, dynamic>>[],
      };

      final status = StudyDeploymentStatus.fromJson(json);

      expect(status.deviceStatusList.length, 2);
      expect(status.deviceStatusList[0].device, isA<Smartphone>());
      expect(status.deviceStatusList[1].device, isA<LocationService>());
      // The aliased instances carry the CAMS 2.x type, so device-manager
      // lookups by type string work.
      expect(status.deviceStatusList[1].device.type, 'dk.carp.cams.devices.LocationService');
    });
  });

  group('StudyService', () {
    late StudyService service;

    setUp(() {
      service = StudyService();
    });

    test('capability queries are false without a deployment', () {
      expect(service.isDeployed, isFalse);
      expect(service.deployment, isNull);
      expect(service.studyStartTimestamp, isNull);
      expect(service.hasMeasures(), isFalse);
      expect(service.hasMeasure(AppTask.SURVEY_TYPE), isFalse);
      expect(service.hasUserTasks(), isFalse);
      expect(service.expectedParticipantData, isEmpty);
    });

    test('start is a safe no-op when the study is not deployed', () async {
      await service.start(); // no controller - must not throw
      expect(service.isRunning, isFalse);
    });

    test('tryDeployment is a safe no-op before the study is added', () async {
      expect(await service.tryDeployment(), isNull);
    });

    test('setting the study persists it and hasStudy reflects it', () {
      service.study = SmartphoneStudy(studyDeploymentId: 'dep-2', deviceRoleName: 'phone');

      expect(service.hasStudy, isTrue);
      expect(service.study?.studyDeploymentId, 'dep-2');
    });

    test('configure throws and stays retryable when deployment cannot succeed', () async {
      service.study = SmartphoneStudy(studyDeploymentId: 'dep-2', deviceRoleName: 'phone');

      // The client manager is not configured in unit tests, so configure()
      // must fail - and fail again on retry rather than being stuck.
      await expectLater(service.configure(), throwsA(anything));
      await expectLater(service.configure(), throwsA(anything));
    });
  });
}
