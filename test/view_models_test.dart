import 'package:carp_backend/carp_backend.dart';
import 'package:carp_audio_package/media.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:fake_async/fake_async.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';
import 'test_utils.dart';
import 'services_test.mocks.dart';

class _FakeMessageManager extends MessageManager {
  List<Message> toReturn = [];

  @override
  void initialize() {}

  @override
  Future<Message?> getMessage(String messageId) async => null;

  @override
  Future<List<Message>> getMessages({DateTime? start, DateTime? end, int? count = 20}) async => List.of(toReturn);

  @override
  Future<void> setMessage(Message message) async {}

  @override
  Future<void> deleteMessage(String messageId) async {}

  @override
  Future<void> deleteAllMessages() async {}
}

void main() {
  setUpAll(() async {
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    await initTestSettings();
    AppConfig.deploymentMode = DeploymentMode.local;
  });

  group('StudyPageViewModel', () {
    test('falls back to defaults when nothing is deployed', () {
      final model = StudyPageViewModel(
        studyService: StudyService(),
        messageService: MessageService(_FakeMessageManager()),
      );

      expect(model.title, 'Unnamed');
      expect(model.description, '');
      expect(model.privacyPolicyUrl, 'https://carp.dk/privacy-policy-app/');
      expect(model.studyDeploymentId, '');
      expect(model.messages, isEmpty);
    });

    test('shows messages from the message service, oldest first', () async {
      final manager = _FakeMessageManager()
        ..toReturn = [
          Message(id: 'new', timestamp: DateTime(2025, 1, 1)),
          Message(id: 'old', timestamp: DateTime(2024, 1, 1)),
        ];
      final messages = MessageService(manager);
      await messages.refresh();
      final model = StudyPageViewModel(studyService: StudyService(), messageService: messages);

      // The service keeps them newest first; the page shows them reversed.
      expect(model.messages.map((m) => m.id), ['old', 'new']);
    });

    test('refresh completes safely when the study is not yet deployed', () async {
      final manager = _FakeMessageManager()..toReturn = [Message(id: 'a', timestamp: DateTime(2024, 1, 1))];
      final messages = MessageService(manager);
      final model = StudyPageViewModel(studyService: StudyService(), messageService: messages);

      await model.refresh(); // no deployment, no controller - must not throw

      expect(model.messages.length, 1);
    });

    test('init checks for an app update and notifies', () async {
      final system = MockSystemInfoService();
      when(system.getAppHasUpdate()).thenAnswer((_) async => true);
      final model = StudyPageViewModel(
        studyService: StudyService(),
        messageService: MessageService(_FakeMessageManager()),
        systemInfoService: system,
      );
      var notified = false;
      model.addListener(() => notified = true);

      model.init(MockSmartphoneStudyController());
      await Future<void>.delayed(Duration.zero);

      expect(model.appUpdateAvailable, isTrue);
      expect(notified, isTrue);
    });
  });

  group('LoginViewModel', () {
    late MockAuthService auth;
    late MockSystemInfoService system;
    late LoginViewModel model;

    setUp(() {
      auth = MockAuthService();
      system = MockSystemInfoService();
      model = LoginViewModel(authService: auth, systemInfoService: system);
    });

    test('signIn is offline without authenticating when there is no connectivity', () async {
      when(system.checkConnectivity()).thenAnswer((_) async => false);

      expect(await model.signIn(), SignInResult.offline);
      verifyNever(auth.authenticate());
    });

    test('signIn initializes, authenticates, and reports success', () async {
      when(system.checkConnectivity()).thenAnswer((_) async => true);
      when(auth.isAuthenticated).thenReturn(true);

      expect(await model.signIn(), SignInResult.success);
      verifyInOrder([auth.initialize(), auth.authenticate()]);
    });

    test('signIn reports failure when authentication did not stick', () async {
      when(system.checkConnectivity()).thenAnswer((_) async => true);
      when(auth.isAuthenticated).thenReturn(false);

      expect(await model.signIn(), SignInResult.failed);
    });

    test('signInWithMagicLink rejects non-link codes without signing in', () async {
      expect(await model.signInWithMagicLink('not a link'), isFalse);
      verifyNever(auth.authenticateWithMagicLink(any));
    });

    test('signInWithMagicLink authenticates with a valid link', () async {
      when(auth.isAuthenticated).thenReturn(true);

      expect(await model.signInWithMagicLink('https://carp.dk/magic'), isTrue);
      verify(auth.authenticateWithMagicLink('https://carp.dk/magic')).called(1);
    });
  });

  group('InvitationsViewModel', () {
    late MockAuthService auth;
    late InvitationsViewModel model;

    setUp(() {
      auth = MockAuthService();
      model = InvitationsViewModel(authService: auth);
    });

    test('loads invitations and notifies', () async {
      final invitation = ActiveParticipationInvitation(
        Participation('dep-1', 'participant-1', AssignedTo()),
        StudyInvitation('Test study'),
      );
      when(auth.getInvitations()).thenAnswer((_) async => [invitation]);
      var notified = false;
      model.addListener(() => notified = true);

      expect(model.isLoading, isTrue);
      await model.loadInvitations();

      expect(model.isLoading, isFalse);
      expect(model.invitations, [invitation]);
      expect(model.getInvitation('dep-1'), invitation);
      expect(notified, isTrue);
    });

    test('reports an error when loading fails', () async {
      when(auth.getInvitations()).thenAnswer((_) async => throw Exception('offline'));

      await model.loadInvitations();

      expect(model.hasError, isTrue);
      expect(model.isLoading, isFalse);
      expect(model.invitations, isEmpty);
    });

    ActiveParticipationInvitation invitation(String deploymentId) =>
        ActiveParticipationInvitation(Participation(deploymentId, 'participant-1', AssignedTo()), StudyInvitation('Study'));

    test('landingRoute targets the single invitation detail when there is exactly one', () async {
      when(auth.getInvitations()).thenAnswer((_) async => [invitation('dep-1')]);
      await model.loadInvitations();

      expect(model.landingRoute, '${InvitationDetailsPage.route}/dep-1');
    });

    test('getInvitation tells apart two deployments of one study', () async {
      // Same participant id on both - only the deployment id is unique.
      final first = invitation('dep-1');
      final second = invitation('dep-2');
      when(auth.getInvitations()).thenAnswer((_) async => [first, second]);
      await model.loadInvitations();

      expect(model.getInvitation('dep-1'), same(first));
      expect(model.getInvitation('dep-2'), same(second));
    });

    test('landingRoute targets the list for zero or multiple invitations', () async {
      when(auth.getInvitations()).thenAnswer((_) async => []);
      await model.loadInvitations();
      expect(model.landingRoute, InvitationListPage.route);

      when(auth.getInvitations()).thenAnswer((_) async => [invitation('a'), invitation('b')]);
      await model.loadInvitations();
      expect(model.landingRoute, InvitationListPage.route);
    });

    test('ensureInvitationsLoaded loads once; loadInvitations always refreshes', () async {
      when(auth.getInvitations()).thenAnswer((_) async => []);

      await model.ensureInvitationsLoaded();
      await model.ensureInvitationsLoaded();
      verify(auth.getInvitations()).called(1); // second call is a no-op

      await model.loadInvitations(); // manual refresh still hits the backend
      verify(auth.getInvitations()).called(1);
    });

    test('ensureInvitationsLoaded retries after a failed load', () async {
      when(auth.getInvitations()).thenAnswer((_) async => throw Exception('offline'));
      await model.ensureInvitationsLoaded();
      expect(model.isLoaded, isFalse);

      when(auth.getInvitations()).thenAnswer((_) async => [invitation('participant-1')]);
      await model.ensureInvitationsLoaded(); // not loaded yet, so it retries
      expect(model.isLoaded, isTrue);
    });
  });

  group('TaskListPageViewModel', () {
    MockUserTask backgroundTask() {
      final task = MockUserTask();
      when(task.state).thenReturn(UserTaskState.enqueued);
      when(task.hasWidget).thenReturn(false);
      when(task.id).thenReturn('task-1');
      return task;
    }

    test('startUserTask auto-completes a background task after 10 seconds', () {
      fakeAsync((async) {
        final task = backgroundTask();
        final model = TaskListPageViewModel(studyService: StudyService());

        expect(model.startUserTask(task), isFalse);
        verify(task.onStart()).called(1);
        verifyNever(task.onDone());

        async.elapse(const Duration(seconds: 11));

        verify(task.onDone()).called(1);
        expect(model.autoCompletedTask, task);
      });
    });

    test('startUserTask does not start an already done task', () {
      final task = MockUserTask();
      when(task.state).thenReturn(UserTaskState.done);

      expect(TaskListPageViewModel(studyService: StudyService()).startUserTask(task), isFalse);
      verifyNever(task.onStart());
    });

    test('clear cancels pending auto-complete timers', () {
      fakeAsync((async) {
        final task = backgroundTask();
        final model = TaskListPageViewModel(studyService: StudyService());

        model.startUserTask(task);
        model.clear();
        async.elapse(const Duration(seconds: 11));

        verifyNever(task.onDone());
        expect(model.autoCompletedTask, isNull);
      });
    });

    test('checkParticipantData shows the card when no data is set', () async {
      final model = TaskListPageViewModel(studyService: StudyService());
      var notified = false;
      model.addListener(() => notified = true);

      await model.checkParticipantData(); // no deployment - data list is empty

      expect(model.showParticipantDataCard, isTrue);
      expect(notified, isTrue);
    });
  });

  group('DataVisualizationPageViewModel', () {
    test('precomputes card availability from the deployment on init', () {
      final study = MockStudyService();
      when(study.hasUserTasks()).thenReturn(true);
      when(study.hasMeasure(PolarSamplingPackage.HR)).thenReturn(true);
      when(study.hasMeasure(MediaSamplingPackage.AUDIO)).thenReturn(true);
      final model = DataVisualizationPageViewModel(studyService: study);

      model.init(MockSmartphoneStudyController());

      expect(model.hasUserTasks, isTrue);
      expect(model.hasHeartRateMeasure, isTrue);
      expect(model.hasAudioMeasure, isTrue);
      expect(model.hasVideoMeasure, isFalse);
      expect(model.hasStepsMeasure, isFalse);
      expect(model.hasMobilityMeasure, isFalse);
    });
  });

  group('ProfilePageViewModel', () {
    test('is empty-safe when signed out and nothing is deployed', () {
      final backend = MockCarpBackend();
      when(backend.user).thenReturn(null);
      when(backend.uri).thenReturn(Uri(scheme: 'https', host: 'test.carp.dk'));

      final model = ProfilePageViewModel(
        authService: AuthService(backend: backend),
        studyService: StudyService(),
      );

      expect(model.username, '');
      expect(model.email, '');
      expect(model.studyId, '');
      expect(model.currentServer, 'https://test.carp.dk');
    });
  });
}
