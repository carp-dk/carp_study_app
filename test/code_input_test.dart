import 'exports.dart';

/// Run [CodeInput.formatters] over [input] as if it was pasted into an empty field.
String format(String input) => CodeInput.formatters
    .fold(
      TextEditingValue(text: input),
      (value, formatter) => formatter.formatEditUpdate(TextEditingValue.empty, value),
    )
    .text;

void main() {
  group('CodeInput', () {
    test('keeps letters and digits, upper-cased', () {
      expect(format('ab3c9'), 'AB3C9');
      expect(format('AB3C9'), 'AB3C9');
    });

    test('masks away anything else, also when pasted', () {
      expect(format('a b-3!c'), 'AB3C');
      expect(format('  code: x1y2z  '), 'CODEX');
      expect(format('æøå'), '');
    });

    test('never exceeds the code length', () {
      expect(format('abcdefghij').length, LoginViewModel.codeLength);
    });
  });
}
