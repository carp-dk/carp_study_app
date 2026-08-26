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

  group('AppBloc.configureStudy', () {
    test('is atomic and retryable - a failed configuration enters the error state', () async {
      final bloc = AppBloc();
      LocalSettings().study = SmartphoneStudy(studyDeploymentId: 'dep-bloc-1', deviceRoleName: 'phone');

      // Sensing cannot be set up in a unit test environment, so the
      // configuration fails - the state must land in `configurationFailed`
      // instead of being stuck in `configuring` (which would block any
      // retry forever).
      await expectLater(bloc.configureStudy(), throwsA(anything));
      expect(bloc.state, AppState.configurationFailed);
      expect(bloc.isConfiguring, isFalse);

      // A retry must run (and fail) again - not silently return.
      await expectLater(bloc.configureStudy(), throwsA(anything));
      expect(bloc.state, AppState.configurationFailed);
    });

    test('surfaces a failure to the UI and clears it when a retry starts', () async {
      final bloc = AppBloc();
      LocalSettings().study = SmartphoneStudy(studyDeploymentId: 'dep-bloc-2', deviceRoleName: 'phone');
      expect(bloc.configurationFailed, isFalse);

      // tryConfigureStudy swallows the error (no caller can handle it), so
      // the state is the only signal the study page has to stop spinning.
      await bloc.tryConfigureStudy();
      expect(bloc.configurationFailed, isTrue);

      // Starting a retry moves to `configuring` so the loader shows again.
      final retry = bloc.tryConfigureStudy();
      expect(bloc.configurationFailed, isFalse);
      expect(bloc.state, AppState.configuring);
      await retry;
      expect(bloc.configurationFailed, isTrue);
    });

    test('throws when no study has been set', () async {
      final bloc = AppBloc();
      await LocalSettings().eraseStudyDeployment();

      await expectLater(bloc.configureStudy(), throwsStateError);
      expect(bloc.isConfiguring, isFalse);
    });
  });
}
