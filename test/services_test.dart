import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

/// The visible words of a PDF - its content streams are zlib deflated, and
/// each word is a separate `(word)Tj` literal.
String _pdfText(Uint8List pdf) {
  final buffer = StringBuffer();
  final raw = String.fromCharCodes(pdf);
  for (final match in RegExp(r'stream\r?\n').allMatches(raw)) {
    final end = raw.indexOf('endstream', match.end);
    if (end < 0) continue;
    try {
      final content = utf8.decode(ZLibDecoder().convert(pdf.sublist(match.end, end)), allowMalformed: true);
      for (final word in RegExp(r'\(((?:[^()\\]|\\.)*)\)').allMatches(content)) {
        buffer.write('${word[1]} ');
      }
    } catch (_) {
      // not a deflated text stream (e.g. an image) - nothing to read
    }
  }
  return buffer.toString();
}

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

/// Records the notifications a service asks for, instead of hitting the platform.
class _FakeNotificationManager implements NotificationManager {
  final List<String> titles = [];

  @override
  Future<int> createNotification({int? id, required String title, String? body}) async {
    titles.add(title);
    return id ?? titles.length;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    AppConfig.deploymentMode = DeploymentMode.local;
  });

  group('AppConfig', () {
    test('defaults to info debug level when no environment is given', () {
      // No --dart-define values are set in tests, so the default applies.
      expect(AppConfig.debugLevel, DebugLevel.info);
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

    test('notifies only about messages that arrive after the first refresh', () async {
      final manager = _FakeMessageManager()..toReturn = [message('a', DateTime(2024, 1, 1))];
      final notifications = _FakeNotificationManager();
      final service = MessageService(manager, notificationManager: notifications);

      await service.refresh();
      expect(notifications.titles, isEmpty, reason: 'the backlog must not be replayed on the first refresh');

      manager.toReturn = [message('a', DateTime(2024, 1, 1)), message('b', DateTime(2025, 1, 1))];
      await service.refresh();
      expect(notifications.titles, ['message-b']);

      await service.refresh();
      expect(notifications.titles, ['message-b'], reason: 'an already seen message must not notify again');
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

    test('getInvitations sorts by study name, then deployment id', () async {
      ActiveParticipationInvitation invitation(String name, String deploymentId) => ActiveParticipationInvitation(
        Participation(deploymentId, 'participant-1', AssignedTo()),
        StudyInvitation(name),
      );

      // CAWS returns these in no particular order; two deployments of one study
      // must still come back in a stable order on every refresh.
      final beta = invitation('Beta', 'dep-1');
      final alphaB = invitation('Alpha', 'dep-b');
      final alphaA = invitation('Alpha', 'dep-a');
      when(backend.getInvitations()).thenAnswer((_) async => [beta, alphaB, alphaA]);

      expect(await auth.getInvitations(), [alphaA, alphaB, beta]);
    });
  });

  group('ConsentService', () {
    late _FakeConsentManager manager;
    late MockCarpBackend backend;
    late ConsentService consent;

    setUp(() {
      manager = _FakeConsentManager();
      backend = MockCarpBackend();
      consent = ConsentService(manager, backend: backend);
    });

    test('getDocument delegates to the consent manager', () async {
      expect(await consent.getDocument(refresh: true), isNull);
      expect(manager.lastRefresh, isTrue);
    });

    test('hasSignedConsent is false without a study, without asking the backend', () async {
      expect(await consent.hasSignedConsent(null), isFalse);
      verifyNever(backend.getInformedConsentByRole(any, any));
    });

    test('hasSignedConsent is false when the backend cannot be reached', () async {
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer((_) async => throw Exception('offline'));

      expect(await consent.hasSignedConsent(study), isFalse);
    });

    test('hasSignedConsent is true when the backend has a signed consent', () async {
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(
        backend.getInformedConsentByRole('dep-1', null),
      ).thenAnswer((_) async => InformedConsentInput(userId: '42', name: 'jdoe', consent: '{}', signatureImage: ''));

      expect(await consent.hasSignedConsent(study), isTrue);
    });

    test('signedConsentBytes returns the signed consent as a readable PDF', () async {
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer(
        (_) async => InformedConsentInput(
          userId: '42',
          name: 'jdoe',
          consent: json.encode(
            RPConsentSignatureResult(
              identifier: 'consent',
              consentDocument: RPConsentDocument(
                title: 'Study Consent',
                sections: [
                  RPConsentSection(type: RPConsentSectionType.Overview, summary: 'What this study does.'),
                ],
              ),
              signature: RPSignatureResult(firstName: 'Jane', lastName: 'Doe'),
            ).toJson(),
          ),
          signatureImage: '',
        ),
      );

      final bytes = await consent.signedConsentBytes(study);

      // This is the file the save dialog writes, so it has to be a PDF the
      // participant can open, with the consent they signed inside it.
      expect(bytes, isNotNull);
      expect(utf8.decode(bytes!.sublist(0, 4)), '%PDF');
      final text = _pdfText(bytes);
      expect(text, contains('Study Consent'));
      expect(text, contains('What this study does.'));
      expect(text, contains('Jane Doe'));
    });

    test('the PDF embeds the signature image stored as Uint8List.toString()', () async {
      // Research Package stores the signature PNG as `[137, 80, 78, ...]`, not
      // as base64 - decoding it as base64 silently loses the signature.
      final png = [
        ...[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0],
        ...[31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 96, 96, 248, 15, 0, 1, 4, 1, 0, 95],
        ...[229, 195, 75, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130],
      ];
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer(
        (_) async =>
            InformedConsentInput(userId: '42', name: 'jdoe', consent: 'I agree', signatureImage: png.toString()),
      );

      final bytes = await consent.signedConsentBytes(study);

      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes!), contains('/Image'));
    });

    test('a consent signed against a newer RP with unknown section types still renders', () async {
      // Seen in the field: a consent document using RPConsentSectionType
      // values (e.g. ActivityRecognition) added after this app's RP version -
      // the enum decoder throws and the whole document used to be dropped.
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer(
        (_) async => InformedConsentInput(
          userId: '42',
          name: 'jdoe',
          consent: json.encode({
            '__type': 'RPConsentSignatureResult',
            'identifier': 'consent',
            'consentDocument': {
              '__type': 'RPConsentDocument',
              'title': 'Study Consent',
              'signatures': <Map<String, dynamic>>[],
              'sections': [
                {
                  '__type': 'RPConsentSection',
                  'type': 'SectionTypeFromTheFuture',
                  'title': 'Activity Recognition',
                  'summary': 'We track your movement.',
                },
                {
                  '__type': 'RPConsentSection',
                  'type': 'Overview',
                  'title': 'Overview',
                  'summary': 'What this study does.',
                },
              ],
            },
            'signature': {'__type': 'RPSignatureResult', 'firstName': 'Jane', 'lastName': 'Doe'},
          }),
          signatureImage: '',
        ),
      );

      final bytes = await consent.signedConsentBytes(study);

      expect(bytes, isNotNull);
      final text = _pdfText(bytes!);
      expect(text, isNot(contains('could not be displayed')));
      expect(text, contains('Activity Recognition'));
      expect(text, contains('We track your movement.'));
      expect(text, contains('What this study does.'));
      expect(text, contains('Jane Doe'));
    });

    test('unparseable consent JSON never dumps signature bytes into the PDF', () async {
      // If the RP JSON cannot be deserialized, falling back to printing it
      // verbatim would fill the PDF with the raw signature byte list.
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer(
        (_) async => InformedConsentInput(
          userId: '42',
          name: 'jdoe',
          consent: '{"__type": "unknown", "signature": "[137, 80, 78, 71, 13, 10]"}',
          signatureImage: '',
        ),
      );

      final bytes = await consent.signedConsentBytes(study);

      expect(bytes, isNotNull);
      final text = _pdfText(bytes!);
      expect(text, isNot(contains('137')));
      expect(text, contains('could not be displayed'));
    });

    test('signedConsentBytes is null when nothing is signed', () async {
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer((_) async => null);

      expect(await consent.signedConsentBytes(study), isNull);
    });

    test('signedConsentBytes is null when the backend cannot be reached', () async {
      final study = SmartphoneStudy(studyDeploymentId: 'dep-1', deviceRoleName: 'phone');
      when(backend.getInformedConsentByRole('dep-1', null)).thenAnswer((_) async => throw Exception('offline'));

      expect(await consent.signedConsentBytes(study), isNull);
    });
  });

  group('Old-namespace CAWS compatibility', () {
    test('a pre-CAMS-2.x deployment status with CAMS device types deserializes', () {
      Sensing(); // registers the sampling packages

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
