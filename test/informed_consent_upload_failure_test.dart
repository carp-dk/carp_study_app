import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import 'exports.dart';
import 'informed_consent_harness.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() async {
    ResearchPackage.ensureInitialized();
    await initTestSettings();
    AppConfig.deploymentMode = DeploymentMode.local;
  });

  testWidgets('a failed upload is recorded once, tells the user, and leaves the study', (tester) async {
    final model = StubConsentViewModel(uploadFails: true);

    await tester.pumpWidget(consentPage(model));
    await tester.pumpAndSettle();
    expect(find.byType(InformedConsentPage), findsOneWidget);

    // The consent review step keeps its DONE button mounted while the upload
    // runs, so it really can be submitted again - which used to start a second
    // upload on top of the first.
    final task = tester.widget<RPUITask>(find.byType(RPUITask));
    final result = RPTaskResult(identifier: 'consent');
    task.onSubmit!(result);
    task.onSubmit!(result);
    await tester.pumpAndSettle();

    expect(model.acceptCalls, 1);

    // The consent never reached CAWS, so the user is not consented - they are
    // told, and the study is left rather than leaving them on a dead screen.
    expect(model.status, isNot(ConsentStatus.given));
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(model.rejected, isTrue);
  });
}
