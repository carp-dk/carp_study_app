part of carp_study_app;

/// What [CarpSphereMorph] shows. The watch app draws the same thing.
enum CarpMorphMode {
  /// The CARP mark, shimmering - collecting, nothing to send right now.
  collecting,

  /// A spinning sphere of fragments that light up with the sync's progress.
  syncing,

  /// The solid CARP mark - the data has arrived.
  sent,

  /// A slow grey sphere - the watch app is closed or out of range.
  away,
}

/// A sphere of CARP-red fragments which morphs into the CARP mark
/// (`assets/carp_logo.svg`) once the data has arrived. Best at 184:150.
class CarpSphereMorph extends StatefulWidget {
  const CarpSphereMorph({super.key, required this.mode, this.progress = 0});

  final CarpMorphMode mode;

  /// Share of the sync done (0-1), lights fragments while [CarpMorphMode.syncing].
  final double progress;

  static const Color red = Color(0xFFD61D41);

  @override
  State<CarpSphereMorph> createState() => _CarpSphereMorphState();
}

class _CarpSphereMorphState extends State<CarpSphereMorph> with SingleTickerProviderStateMixin {
  final _clock = _MorphClock();
  late final _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _clock.formed = widget.mode == CarpMorphMode.syncing || widget.mode == CarpMorphMode.away ? 0 : 1;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final mode = widget.mode;
    final formed = mode == CarpMorphMode.collecting || mode == CarpMorphMode.sent ? 1.0 : 0.0;
    final solid = mode == CarpMorphMode.sent && _clock.formed > 0.98 ? 1.0 : 0.0;
    if (MediaQuery.of(context).disableAnimations) {
      _clock.update(_clock.time, formed, solid);
    } else {
      _clock.update(
        _clock.time + dt * (mode == CarpMorphMode.away ? 0.2 : 1),
        _clock.formed + (formed - _clock.formed).clamp(-dt / 1.7, dt / 1.7),
        _clock.solid + (solid - _clock.solid) * min(1, dt * 4),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SphereMorphPainter(_clock, widget.mode, widget.progress), size: Size.infinite);
}

class _MorphClock extends ChangeNotifier {
  double time = 0, formed = 1, solid = 0;

  void update(double time, double formed, double solid) {
    this.time = time;
    this.formed = formed;
    this.solid = solid;
    notifyListeners();
  }
}

class _Dot {
  _Dot(this.logo, this.white);
  final Offset logo;
  final bool white;
  late final double sx, sy, sz, delay, k;
}

class _SphereMorphPainter extends CustomPainter {
  _SphereMorphPainter(this.clock, this.mode, this.progress) : super(repaint: clock);

  final _MorphClock clock;
  final CarpMorphMode mode;
  final double progress;

  // The mark from assets/carp_logo.svg, in its SVG units (38 wide, y 6-25.3).
  static final Path _body = Path()
    ..moveTo(28.4426, 6)
    ..lineTo(9.47791, 6)
    ..lineTo(9.47791, 15.6412)
    ..cubicTo(9.47791, 20.9637, 13.7211, 25.2825, 18.9603, 25.2825)
    ..lineTo(28.4426, 25.2825)
    ..cubicTo(33.6774, 25.2825, 37.925, 20.9682, 37.925, 15.6412)
    ..cubicTo(37.925, 10.3188, 33.6818, 6, 28.4426, 6)
    ..close();
  static final Path _tail = Path()
    ..moveTo(9.48236, 15.6412)
    ..cubicTo(9.48236, 10.3188, 5.23473, 6, 0, 6)
    ..lineTo(0, 25.2825)
    ..cubicTo(5.23473, 25.2825, 9.48236, 20.9682, 9.48236, 15.6412)
    ..close();
  static final Path _plus = Path()
    ..addPolygon(const [
      Offset(32.5409, 14.2741),
      Offset(29.0705, 14.2741),
      Offset(29.0705, 10.75),
      Offset(26.3861, 10.75),
      Offset(26.3861, 14.2741),
      Offset(22.9156, 14.2741),
      Offset(22.9156, 17.0034),
      Offset(26.3861, 17.0034),
      Offset(26.3861, 20.532),
      Offset(29.0705, 20.532),
      Offset(29.0705, 17.0034),
      Offset(32.5409, 17.0034),
    ], true);

  static const double _logoWidth = 37.925, _logoMiddle = 15.64, _grid = 0.78;

  /// Dots spaced evenly along each outline (so straight edges stay straight),
  /// then a regular grid inside, kept clear of the outlines.
  static final List<_Dot> dots = () {
    final dots = <_Dot>[];
    for (final (path, white) in [(_body, false), (_tail, false), (_plus, true)]) {
      for (final metric in path.computeMetrics()) {
        final n = (metric.length / _grid).round();
        for (var i = 0; i < n; i++) {
          dots.add(_Dot(metric.getTangentForOffset(i * metric.length / n)!.position, white));
        }
      }
    }
    final outline = [for (final d in dots) d.logo];
    for (var y = 6 + _grid; y < 25.3; y += _grid) {
      for (var x = _grid / 2; x < _logoWidth; x += _grid) {
        final p = Offset(x, y);
        if (outline.any((o) => (o - p).distance < _grid * 0.75)) continue;
        if (_plus.contains(p)) {
          dots.add(_Dot(p, true));
        } else if (_body.contains(p) || _tail.contains(p)) {
          dots.add(_Dot(p, false));
        }
      }
    }
    final random = Random(1);
    dots.shuffle(random);
    for (var i = 0; i < dots.length; i++) {
      // Golden-angle spiral: evenly spread points on a unit sphere.
      final y = 1 - 2 * (i + 0.5) / dots.length, r = sqrt(1 - y * y), a = i * 2.39996;
      dots[i]
        ..sx = cos(a) * r
        ..sy = y
        ..sz = sin(a) * r
        ..delay = random.nextDouble() * 0.45
        ..k = random.nextDouble();
    }
    return dots;
  }();

  static const _grey = Color(0xFF5F5F64), _unlit = Color(0xFF50101E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, unit = w / 184;
    final scale = 0.72 * w / _logoWidth;
    final logoOrigin = Offset((w - _logoWidth * scale) / 2, h / 2 - _logoMiddle * scale);
    final radius = min(0.3 * w, 0.42 * h), center = Offset(w / 2, h / 2);
    final t = clock.time, rot = t * 0.75, cr = cos(rot), sr = sin(rot), ct = cos(0.35), st = sin(0.35);
    final paint = Paint();
    final fade = 1 - clock.solid;

    if (fade > 0.01) {
      for (final d in dots) {
        var x = d.sx * cr + d.sz * sr, z = -d.sx * sr + d.sz * cr;
        final y = d.sy * ct - z * st;
        z = d.sy * st + z * ct;
        final s = 1 / (1 + z * 0.35), depth = (1 - z) / 2;
        final onSphere = center + Offset(x * radius * s, y * radius * s);
        final onLogo = logoOrigin + d.logo * scale;
        var u = ((clock.formed - d.delay) / 0.55).clamp(0.0, 1.0);
        u = u * u * (3 - 2 * u);

        final sphereColor = mode == CarpMorphMode.away
            ? _grey
            : mode == CarpMorphMode.syncing && d.k >= progress
            ? _unlit
            : CarpSphereMorph.red;
        var color = Color.lerp(sphereColor, d.white ? Colors.white : CarpSphereMorph.red, u)!;
        // Collecting: a wave of brightness runs across the still mark.
        if (mode == CarpMorphMode.collecting && !d.white) {
          color = Color.lerp(Colors.black, color, 0.82 + 0.18 * sin(t * 2 - onLogo.dx / unit * 0.08))!;
        }
        paint.color = color.withValues(alpha: (((0.3 + 0.7 * depth) * (1 - u) + u) * fade).clamp(0.0, 1.0));
        canvas.drawCircle(Offset.lerp(onSphere, onLogo, u)!, ((1 + depth * 1.3) * (1 - u) + 1.3 * u) * unit, paint);
      }
    }

    if (clock.solid > 0.01) {
      canvas
        ..save()
        ..translate(logoOrigin.dx, logoOrigin.dy)
        ..scale(scale);
      paint.color = CarpSphereMorph.red.withValues(alpha: clock.solid);
      canvas
        ..drawPath(_body, paint)
        ..drawPath(_tail, paint);
      paint.color = Colors.white.withValues(alpha: clock.solid);
      canvas
        ..drawPath(_plus, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_SphereMorphPainter old) => old.mode != mode || old.progress != progress;
}
