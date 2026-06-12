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
