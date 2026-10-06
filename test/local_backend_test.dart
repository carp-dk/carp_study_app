import 'dart:io';

import 'package:cognition_package/cognition_package.dart';
import 'package:research_package/research_package.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exports.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() async {
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    await initTestSettings();
    AppConfig.deploymentMode = DeploymentMode.local;
    await Backend().initialize();
  });

  test('local mode uses the local backend and signs in like CAWS', () async {
    final backend = Backend();
    expect(backend, isA<LocalBackend>());
    expect(backend.isAuthenticated, isFalse);

    await backend.authenticate();
    expect(backend.isAuthenticated, isTrue);

    await backend.signOut();
    expect(backend.isAuthenticated, isFalse);
  });

  // assets/carp is gitignored (study configs are private), so CI has no protocol.
  final noProtocol = File('assets/carp/resources/protocol.json').existsSync() ? false : 'no local protocol.json';

  test('the one invitation is the bundled protocol, assigned to this phone', skip: noProtocol, () async {
    await Backend().authenticate();
    final invitations = await AuthService().getInvitations();

    expect(invitations, hasLength(1));
    expect(invitations.single.invitation.description, isNot(startsWith('study.')), reason: 'key, not translated');
    final study = SmartphoneStudy.fromInvitation(invitations.single);
    expect(study.deviceRoleName, isNotEmpty);
    final deployment = await SmartphoneDeploymentService().getDeviceDeploymentFor(
      study.studyDeploymentId,
      study.deviceRoleName,
    );
    expect(deployment?.deviceConfiguration.roleName, study.deviceRoleName);
  });

  test('signed consent is kept in memory until sign-out', () async {
    final study = SmartphoneStudy(studyDeploymentId: 'dep-consent', deviceRoleName: 'phone');
    LocalSettings().study = study;
    await Backend().authenticate();
    expect(await ConsentService(LocalResourceManager()).hasSignedConsent(study), isFalse);

    final result = RPTaskResult(identifier: 'consent')
      ..results['signature'] = RPConsentSignatureResult(
        identifier: 'signature',
        consentDocument: RPConsentDocument(title: 'Consent', sections: []),
        signature: RPSignatureResult(firstName: 'Ann', signatureImage: 'png'),
      );
    await ConsentService(LocalResourceManager()).upload(result);
    expect(await ConsentService(LocalResourceManager()).hasSignedConsent(study), isTrue);

    await Backend().signOut();
    expect(await ConsentService(LocalResourceManager()).hasSignedConsent(study), isFalse);
  });

  test('nothing is written to shared preferences', () async {
    LocalSettings().study = SmartphoneStudy(studyDeploymentId: 'dep-local', deviceRoleName: 'phone');
    LocalSettings().isAnonymous = true;

    expect(LocalSettings().study?.studyDeploymentId, 'dep-local');
    expect(LocalSettings().isAnonymous, isTrue);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);

    await LocalSettings().eraseStudyDeployment();
    expect(LocalSettings().study, isNull);
  });
}
