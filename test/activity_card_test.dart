import 'exports.dart';

void main() {
  test('zero-minute activities take no room in the stack', () {
    // Walking then cycling: one gap between them, none reserved for running.
    expect(stackSegments([65, 0, 7], 2), [(0, 0.0, 65.0), (2, 67.0, 74.0)]);
    expect(stackSegments([0, 0, 0], 2), isEmpty);
    // A lone activity starts at the axis, whichever it is.
    expect(stackSegments([0, 12, 0], 2), [(1, 0.0, 12.0)]);
  });
}
