import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/app/carp_study_app.dart';

/// Every supported language has all English keys with the same placeholders -
/// a missing key shows up as the raw key in the app.
void main() {
  Map<String, dynamic> load(String code) =>
      json.decode(File('assets/lang/$code.json').readAsStringSync()) as Map<String, dynamic>;
  Set<String> placeholders(Object? text) => RegExp(r'{{\w+}}').allMatches('$text').map((m) => m[0]!).toSet();

  final en = load('en');
  for (final code in ['da', 'sv', 'nb', 'fi', 'de', 'fr', 'it', 'es', 'pt']) {
    test('$code.json matches en.json', () {
      final translation = load(code);
      expect(translation.keys.toSet(), en.keys.toSet());
      for (final key in en.keys) {
        expect(placeholders(translation[key]), placeholders(en[key]), reason: key);
      }
    });
  }

  testWidgets('a language Research Package lacks falls back to English, not raw keys', (tester) async {
    final de = await AppLocalizationsDelegate(loaders: [const AssetLocalizationLoader()]).load(const Locale('de'));
    expect(de.translate('discard_confirmation'), 'Leave survey?', reason: 'RP has no German');
    expect(de.translate('next'), 'Weiter', reason: 'the app translation wins');
  });
}
