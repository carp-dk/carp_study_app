import 'package:cognition_package/cognition_package.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() async {
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    await initTestSettings();
    AppConfig.deploymentMode = DeploymentMode.local;
  });

  group('StudyAppBLoC.configureStudy', () {
    test('is atomic and retryable - a failed configuration resets the state', () async {
      final bloc = StudyAppBLoC();
      LocalSettings().study = SmartphoneStudy(studyDeploymentId: 'dep-bloc-1', deviceRoleName: 'phone');

      // Sensing cannot be set up in a unit test environment, so the
      // configuration fails - the state must roll back instead of being
      // stuck in `configuring` (which would block any retry forever).
      await expectLater(bloc.configureStudy(), throwsA(anything));
      expect(bloc.state, StudyAppState.created);
      expect(bloc.isConfiguring, isFalse);

      // A retry must run (and fail) again - not silently return.
      await expectLater(bloc.configureStudy(), throwsA(anything));
      expect(bloc.state, StudyAppState.created);
    });

    test('throws when no study has been set', () async {
      final bloc = StudyAppBLoC();
      await LocalSettings().eraseStudyDeployment();

      await expectLater(bloc.configureStudy(), throwsStateError);
      expect(bloc.isConfiguring, isFalse);
    });
  });
}
