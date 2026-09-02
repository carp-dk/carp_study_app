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

  testWidgets('signing shows the app, and refreshing the router does not bring consent back', (tester) async {
    final model = StubConsentViewModel();
    // Stands in for the bloc: configuring the study refreshes the router, which
    // is what used to replay the pushed consent route on top of the app.
    final refresh = ChangeNotifier();

    await tester.pumpWidget(consentApp(model, refresh: refresh));
    await tester.pumpAndSettle();
    expect(find.byType(InformedConsentPage), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    expect(model.uploads, 1);
    expect(await model.needsSigning(), isFalse);
    expect(find.byType(InformedConsentPage), findsNothing);

    refresh.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.byType(InformedConsentPage), findsNothing);
  });
}
