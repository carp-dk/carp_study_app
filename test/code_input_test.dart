import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exports.dart';

/// Run [CodeInput.formatters] over [input] as if it was typed into a box holding [old].
String format(String input, {String old = ''}) => CodeInput.formatters
    .fold(
      TextEditingValue(text: input),
      (TextEditingValue value, TextInputFormatter formatter) =>
          formatter.formatEditUpdate(TextEditingValue(text: old), value),
    )
    .text;

void main() {
  group('CodeInput', () {
    test('keeps letters and digits, upper-cased', () {
      expect(format('a'), 'A');
      expect(format('3'), '3');
    });

    test('masks away anything else, also when pasted', () {
      expect(format(' '), '');
      expect(format('-'), '');
      expect(format('æ'), '');
    });

    test('one character per box', () {
      expect(format('a3', old: 'A'), '3', reason: 'typing into a filled box replaces it');
      expect(format('ab-3'), 'AB3', reason: 'a paste is kept whole');
    });

    testWidgets('a pasted code fills every box and completes', (tester) async {
      final controller = TextEditingController();
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeInput(controller: controller, focusNode: FocusNode(), onCompleted: () => completed = true),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'ab-3c9');
      await tester.pump();

      expect(controller.text, 'AB3C9');
      expect(completed, isTrue);
    });
  });
}
