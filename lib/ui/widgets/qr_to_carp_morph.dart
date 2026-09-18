part of carp_study_app;

/// Morphs a stylised QR code into the CARP mark.
///
/// The mark is sampled from `assets/logo.png` (see [load]) so shape and plus
/// match the real logo. Every lit QR cell flies to a mark cell (paired in
/// reading order so paths never cross), recolouring on the way; mark cells
/// left without a QR cell grow in as the flight lands.
/// [progress] runs 0 → 1; driving it backwards un-morphs on failure.
class QrToCarpMorph extends StatelessWidget {
  const QrToCarpMorph({required this.progress, super.key});

  /// How long the forward morph is designed to take; drive [progress] with this.
  static const Duration duration = Duration(milliseconds: 1600);

  /// A version-1 QR code is 21 × 21 modules; drawn at 2 cells per module so
  /// the mark gets a finer grid while the QR keeps its look.
  static const int modules = 42;

  static _Mark? _mark;

  /// Sample the logo asset into the mark grid. Must complete before this
  /// widget is built; safe to call repeatedly.
  static Future<void> load() async => _mark ??= await _Mark.fromAsset('assets/logo.png', modules);

  final Animation<double> progress;

  /// The painter behind this widget, for drawing a frame directly onto a canvas.
  CustomPainter get painter => _MorphPainter(progress, _mark!);

  @override
  Widget build(BuildContext context) => CustomPaint(painter: painter);
}

class _MorphPainter extends CustomPainter {
  _MorphPainter(this.progress, this.mark) : super(repaint: progress);

  final Animation<double> progress;
  final _Mark mark;

  static const Curve _move = Curves.easeInOutCubic;
  static const int n = QrToCarpMorph.modules;

  /// Fraction of the timeline over which departures are staggered by row.
  static const double _stagger = 0.35;

  /// Lit QR cells and mark cells, both in reading order.
  static final List<int> _qrCells = [
    for (var i = 0; i < n; i++)
      for (var j = 0; j < n; j++)
        if (_qrOn(i, j)) i * n + j,
  ];
  late final List<int> _markCells = [
    for (var k = 0; k < n * mark.rows; k++)
      if (mark.at(k ~/ n, k % n) != _Cell.empty) k,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final origin = Offset((size.width - unit) / 2, (size.height - unit) / 2);
    final t = progress.value;
    final cell = unit / n;
    // The mark is as wide as the QR but shorter; centre it vertically.
    final markTop = (unit - cell * mark.rows) / 2;
    final paint = Paint();

    Offset qrPos(int k) => Offset((k % n + 0.5) * cell, (k ~/ n + 0.5) * cell);
    Offset markPos(int k) => Offset((k % n + 0.5) * cell, markTop + (k ~/ n + 0.5) * cell);
    Color markColor(int k) => mark.at(k ~/ n, k % n) == _Cell.plus ? Colors.white : mark.color;
    // Top rows leave first, so the QR dissolves from the top down.
    double local(int k) => _move.transform(((t - _stagger * (k ~/ n) / n) / (1 - _stagger)).clamp(0.0, 1.0));

    void draw(Offset center, double w, double h, Color color, double alpha) {
      if (alpha <= 0) return;
      paint.color = color.withValues(alpha: alpha);
      canvas.drawRect(Rect.fromCenter(center: origin + center, width: w, height: h), paint);
    }

    // Each lit QR cell flies to the mark cell at the same relative position
    // in reading order; several may share one target and simply merge.
    final qrCount = _qrCells.length, markCount = _markCells.length;
    for (var q = 0; q < qrCount; q++) {
      final from = _qrCells[q];
      final to = _markCells[q * markCount ~/ qrCount];
      final m = local(from);
      final center = origin + Offset.lerp(qrPos(from), markPos(to), m)!;
      // A 2 × 2 block of cells reads as one QR module: hairline gap on the
      // block's outer edges only; slight bleed in the mark so no seams show.
      final gap = (1 - m) * 0.8, bleed = m * 0.35;
      final i = from ~/ n, j = from % n;
      paint.color = Color.lerp(Colors.white, markColor(to), m)!;
      canvas.drawRect(
        Rect.fromLTRB(
          center.dx - cell / 2 + (j.isEven ? gap : 0) - bleed,
          center.dy - cell / 2 + (i.isEven ? gap : 0) - bleed,
          center.dx + cell / 2 - (j.isOdd ? gap : 0) + bleed,
          center.dy + cell / 2 - (i.isOdd ? gap : 0) + bleed,
        ),
        paint,
      );
    }

    // Mark cells nobody flies to fade in on the same clock as the cells
    // landing around them, so no half-formed pixels show mid-flight.
    final covered = {for (var q = 0; q < qrCount; q++) _markCells[q * markCount ~/ qrCount]};
    for (final k in _markCells) {
      if (covered.contains(k)) continue;
      final fill = ((local(k) - 0.7) / 0.3).clamp(0.0, 1.0);
      draw(markPos(k), cell + 0.7, cell + 0.7, markColor(k), fill);
    }
  }

  /// Three finder patterns with quiet zones, timing patterns, and a
  /// deterministic pseudo-random data area - on a 21-module QR, each module
  /// being 2 × 2 cells.
  static bool _qrOn(int cellRow, int cellColumn) {
    const m = n ~/ 2;
    final i = cellRow ~/ 2, j = cellColumn ~/ 2;
    bool finder(int top, int left) {
      final u = i - top, w = j - left;
      if (u < 0 || u > 6 || w < 0 || w > 6) return false;
      return u == 0 || u == 6 || w == 0 || w == 6 || (u >= 2 && u <= 4 && w >= 2 && w <= 4);
    }

    final inFinder = (i < 8 && j < 8) || (i < 8 && j >= m - 8) || (i >= m - 8 && j < 8);
    if (inFinder) return finder(0, 0) || finder(0, m - 7) || finder(m - 7, 0);
    if (i == 6 || j == 6) return (i + j).isEven;
    return ((i * 73856093) ^ (j * 19349663)) % 7 < 3;
  }

  @override
  bool shouldRepaint(_MorphPainter old) => old.mark != mark;
}

enum _Cell { empty, red, plus }

/// The CARP mark sampled onto [columns] × [rows] square cells, the same size
/// as the QR cells, so the mark keeps the logo's aspect ratio.
class _Mark {
  _Mark._(this.columns, this.rows, this.color, this._cells);

  final int columns;
  final int rows;
  final Color color;
  final List<_Cell> _cells;

  _Cell at(int i, int j) => _cells[i * columns + j];

  /// Crop the asset to the bounding box of its coloured (non-white, opaque)
  /// pixels and sample it [columns] wide. White pixels with colour on both
  /// sides in their row are the plus; other white is background.
  static Future<_Mark> fromAsset(String asset, int columns) async {
    final bytes = await rootBundle.load(asset);
    final image = await decodeImageFromList(bytes.buffer.asUint8List());
    final rgba = (await image.toByteData())!;
    final w = image.width, h = image.height;
    bool inked(int x, int y) {
      final o = (y * w + x) * 4;
      return rgba.getUint8(o + 3) > 128 &&
          (rgba.getUint8(o) < 230 || rgba.getUint8(o + 1) < 230 || rgba.getUint8(o + 2) < 230);
    }

    var left = w, right = 0, top = h, bottom = 0;
    final counts = <int, int>{};
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (!inked(x, y)) continue;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
        if ((x + y) % 4 == 0) counts.update(rgba.getUint32((y * w + x) * 4), (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final boxW = right - left + 1, boxH = bottom - top + 1;
    final rows = (columns * boxH / boxW).round();
    final rgbaMost = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final color = Color.fromARGB(rgbaMost & 0xFF, rgbaMost >>> 24, (rgbaMost >> 16) & 0xFF, (rgbaMost >> 8) & 0xFF);

    // Per row and column: the first and last inked pixel. Un-inked pixels
    // enclosed by ink both ways are the plus; the disc/D gap is open at the
    // top and bottom so it is excluded.
    final rowFirst = List<int>.filled(h, w), rowLast = List<int>.filled(h, -1);
    final colFirst = List<int>.filled(w, h), colLast = List<int>.filled(w, -1);
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        if (!inked(x, y)) continue;
        if (x < rowFirst[y]) rowFirst[y] = x;
        rowLast[y] = x;
        if (y < colFirst[x]) colFirst[x] = y;
        colLast[x] = y;
      }
    }
    bool enclosed(int x, int y) => x > rowFirst[y] && x < rowLast[y] && y > colFirst[x] && y < colLast[x];

    // The plus is an exact cross in the logo. Measure it in pixels: its
    // bounding box, and the arm thickness from the box's top row.
    var pLeft = w, pRight = -1, pTop = h, pBottom = -1;
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        if (inked(x, y) || !enclosed(x, y)) continue;
        if (x < pLeft) pLeft = x;
        if (x > pRight) pRight = x;
        if (y < pTop) pTop = y;
        if (y > pBottom) pBottom = y;
      }
    }
    var armW = 0;
    for (var x = pLeft; x <= pRight; x++) {
      if (!inked(x, pTop) && enclosed(x, pTop)) armW++;
    }
    // A plain cross in whole cells: same integer thickness and length for both
    // arms, centred on the plus' centre cell. Exact scale is not the point.
    final scale = columns / boxW;
    final ci = ((pTop + pBottom) / 2 - top) * scale, cj = ((pLeft + pRight) / 2 - left) * scale;
    final halfLen = ((pRight - pLeft + 1) * scale).round() ~/ 2, halfArm = (armW * scale).round() ~/ 2;
    bool plus(int i, int j) {
      final di = (i - ci.round()).abs(), dj = (j - cj.round()).abs();
      return (di <= halfArm && dj <= halfLen) || (dj <= halfArm && di <= halfLen);
    }

    // Each cell takes the majority of the pixels under it (ink or plus = mark).
    final cells = List<_Cell>.filled(columns * rows, _Cell.empty);
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < columns; j++) {
        final x0 = left + (j / scale).floor(), x1 = left + ((j + 1) / scale).ceil();
        final y0 = top + (i / scale).floor(), y1 = top + ((i + 1) / scale).ceil();
        var mark = 0, total = 0;
        for (var y = y0; y < y1 && y <= bottom; y++) {
          for (var x = x0; x < x1 && x <= right; x++) {
            total++;
            if (inked(x, y) || enclosed(x, y)) mark++;
          }
        }
        if (mark * 2 > total) cells[i * columns + j] = plus(i, j) ? _Cell.plus : _Cell.red;
      }
    }
    return _Mark._(columns, rows, color, cells);
  }
}
