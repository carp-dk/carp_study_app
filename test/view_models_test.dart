import 'package:carp_backend/carp_backend.dart';
import 'package:cognition_package/cognition_package.dart';
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
    AppConfig().deploymentMode = DeploymentMode.local;
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
      expect(model.getInvitation('participant-1'), invitation);
      expect(notified, isTrue);
    });

    test('reports an error when loading fails', () async {
      when(auth.getInvitations()).thenAnswer((_) async => throw Exception('offline'));

      await model.loadInvitations();

      expect(model.hasError, isTrue);
      expect(model.isLoading, isFalse);
      expect(model.invitations, isEmpty);
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
