import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_study_app/app/carp_study_app.dart';
import 'package:carp_study_app/features/tasks/participant_data_page.dart';
import 'package:carp_study_app/features/tasks/participant_data_view_model.dart';
import 'package:carp_themes_package/carp_themes_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:research_package/research_package.dart';

class _FakeParticipantDataModel extends ParticipantDataPageViewModel {
  final Set<ExpectedParticipantData?> _expected;
  final String _role;
  Map<String, Data>? saved;

  _FakeParticipantDataModel(this._expected, {String role = 'Participant'}) : _role = role;

  @override
  Set<ExpectedParticipantData?> get expectedData => _expected;

  @override
  List<String> get askableData => askableParticipantData(_expected, _role);

  @override
  Future<void> setParticipantData(Map<String, Data> data) async => saved = data;
}

ExpectedParticipantData _expect(String type, [Set<String>? roles]) => ExpectedParticipantData(
  attribute: ParticipantAttribute(inputDataType: type),
  assignedTo: AssignedTo(roleNames: roles),
);

class _SyncRPLocalizationsDelegate extends LocalizationsDelegate<RPLocalizations> {
  final RPLocalizations localizations;
  const _SyncRPLocalizationsDelegate(this.localizations);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RPLocalizations> load(Locale locale) => SynchronousFuture(localizations);

  @override
  bool shouldReload(_SyncRPLocalizationsDelegate old) => false;
}

Widget _harness(_FakeParticipantDataModel model, RPLocalizations localizations) {
  final router = GoRouter(
    initialLocation: '/',
    overridePlatformDefaultLocation: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(onPressed: () => context.push('/form'), child: const Text('open')),
        ),
      ),
      GoRoute(
        path: '/form',
        builder: (_, _) => ParticipantDataPage(model: model),
      ),
    ],
  );
  return MaterialApp.router(
    theme: carpTheme,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: [
      _SyncRPLocalizationsDelegate(localizations),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );
}

void main() {
  late RPLocalizations localizations;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    localizations = await AppLocalizationsDelegate(loaders: [const AssetLocalizationLoader()]).load(const Locale('en'));
  });

  testWidgets('matches Research Package step flow and saves Jakob #734 participant data', (tester) async {
    final model = _FakeParticipantDataModel({
      _expect(InputType.LANGUAGE),
      _expect(InputType.EDUCATIONAL_DEGREE, {'Participant'}),
      _expect(InputType.OCCUPATION, {'Participant'}),
      _expect(InputType.SEX, {'Participant'}),
      _expect(InputType.INFORMED_CONSENT, {'Participant'}),
    });

    await tester.pumpWidget(_harness(model, localizations));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Step 1 of 6 (intro + 4 data steps + review): RP top bar, no BACK button yet.
    expect(find.text('1 of 6'), findsOneWidget);
    expect(find.byIcon(Icons.highlight_off), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'NEXT'), findsOneWidget);

    // Cancel dialog matches RP: CANCEL (OutlinedButton) & LEAVE (FilledButton).
    await tester.tap(find.byIcon(Icons.highlight_off));
    await tester.pumpAndSettle();
    expect(find.text('Your answers will not be saved.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'CANCEL'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'LEAVE'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'CANCEL'));
    await tester.pumpAndSettle();

    // Advance to Sex (single-choice with Radio + RP hint).
    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 6'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'BACK'), findsOneWidget);
    expect(find.text('(Choose one option)'), findsOneWidget);
    expect(find.byType(Radio<String>), findsNWidgets(Sex.values.length));
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'NEXT')).onPressed, isNull);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pumpAndSettle();

    // Language (single-choice).
    expect(find.text('3 of 6'), findsOneWidget);
    await tester.tap(find.text('Dansk'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pumpAndSettle();

    // Occupation (multi-choice with Checkbox + RP hint).
    expect(find.text('4 of 6'), findsOneWidget);
    expect(find.text('(Choose one or more options)'), findsOneWidget);
    expect(find.byType(Checkbox), findsWidgets);
    await tester.ensureVisible(find.text('Engineer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineer'));
    await tester.ensureVisible(find.text('Researcher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Researcher'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pumpAndSettle();

    // Education (single-choice): scroll position resets so the step title is visible at top.
    expect(find.text('5 of 6'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Highest completed education')).dy, greaterThan(0));

    // Going BACK keeps answers, and deselecting disables NEXT again.
    await tester.tap(find.widgetWithText(OutlinedButton, 'BACK'));
    await tester.pumpAndSettle();
    expect(find.text('4 of 6'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Master's or equivalent"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Master's or equivalent"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pumpAndSettle();

    // Review -> DONE saves all 4 inputs.
    expect(find.text('6 of 6'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Dansk'), findsOneWidget);
    expect(find.text('Engineer, Researcher'), findsOneWidget);
    expect(find.text("Master's or equivalent"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'DONE'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);

    expect(model.saved?.keys.toSet(), {
      InputType.SEX,
      InputType.LANGUAGE,
      InputType.OCCUPATION,
      InputType.EDUCATIONAL_DEGREE,
    });
    expect((model.saved![InputType.SEX] as SexInput).value, Sex.Female);
    expect((model.saved![InputType.LANGUAGE] as PreferredLanguageInput).languageCode, 'da');
    expect((model.saved![InputType.OCCUPATION] as OccupationInput).roles, ['Engineer', 'Researcher']);
    expect((model.saved![InputType.EDUCATIONAL_DEGREE] as EducationalDegreeInput).level, IscedLevel.ISCED_7);
  });

  testWidgets('LEAVE in cancel dialog pops without saving', (tester) async {
    final model = _FakeParticipantDataModel({
      _expect(InputType.SEX, {'Participant'}),
    });
    await tester.pumpWidget(_harness(model, localizations));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.highlight_off));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'LEAVE'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(model.saved, isNull);
  });
}
