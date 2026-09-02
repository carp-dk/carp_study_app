import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // rootBundle caches the translation asset's Future. Created in one test's
  // FakeAsync zone, it never completes in the next - and Localizations then
  // never builds the app. Loading fresh per test keeps futures in their zone.
  setUp(rootBundle.clear);

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

  testWidgets('declining rejects without popping the only route', (tester) async {
    final model = StubConsentViewModel();

    await tester.pumpWidget(consentApp(model));
    await tester.pumpAndSettle();

    // The close button opens RP's cancel confirmation dialog; LEAVE used to
    // pop the task's route too - the only one in the stack, crashing go_router.
    await tester.tap(find.byIcon(Icons.highlight_off));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LEAVE'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(model.rejected, isTrue);
    expect(find.byType(InformedConsentPage), findsOneWidget);
  });
}
