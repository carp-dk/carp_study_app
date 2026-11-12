part of carp_study_app;

/// Live data from a connected Movesense or Polar sensor, so the participant sees it works.
class DeviceLiveDataPage extends StatelessWidget {
  final ConnectionViewModel device;
  const DeviceLiveDataPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade700,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(
                    locale.translate(device.typeName),
                    style: theme.textTheme.titleMedium!.copyWith(color: Colors.grey.shade900),
                  ),
                  Text(device.name, style: theme.textTheme.bodyMedium!.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  DeviceLiveMonitor(device: device),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bedside-monitor view: ECG trace, pulsing BPM, RR interval, and (Movesense) taps.
///
/// HR and taps come from the study's [measurements], since the sensor allows only one
/// state subscription. ECG is streamed straight from the sensor while this is shown.
class DeviceLiveMonitor extends StatefulWidget {
  final ConnectionViewModel device;

  /// The study's measurements - defaults to the running study's.
  final Stream<Measurement>? measurements;

  const DeviceLiveMonitor({super.key, required this.device, this.measurements});

  static bool supports(DeviceManager manager) => manager is MovesenseDeviceManager || manager is PolarDeviceManager;

  @override
  State<DeviceLiveMonitor> createState() => _DeviceLiveMonitorState();
}

enum _LiveStatus { connecting, live, silent }

class _DeviceLiveMonitorState extends State<DeviceLiveMonitor> with TickerProviderStateMixin {
  static const _green = Color(0xff67CE67);
  static const _silentAfterSeconds = 5;

  late final bool _isMovesense = widget.device.deviceManager is MovesenseDeviceManager;
  // 4 s of ECG at the sensor's rate: Movesense /Meas/ECG/125, Polar H10 130 Hz.
  late final _ecg = _EcgSweep(_isMovesense ? 125 : 130);
  late final Ticker _sweep;
  late final _heart = AnimationController(vsync: this, duration: const Duration(milliseconds: 350), value: 1);
  late final _tapFlash = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: 1);
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _clock;

  double? _bpm;
  int? _rr;
  int _taps = 0;
  bool _hasData = false;
  int _quietSeconds = 0;

  /// Seconds since the last real heart rate. The sensor stops sending HR without skin
  /// contact, while the ECG keeps streaming a flat line - so HR needs its own timeout.
  int _hrAgeSeconds = 0;
  bool _ecgUnavailable = false;

  _LiveStatus get _status {
    if (_quietSeconds > _silentAfterSeconds) return _LiveStatus.silent;
    return _hasData ? _LiveStatus.live : _LiveStatus.connecting;
  }

  bool get _hrStale => _hrAgeSeconds > _silentAfterSeconds;

  @override
  void initState() {
    super.initState();
    _sweep = createTicker(_ecg.advance)..start();
    final measurements = widget.measurements ?? bloc.study.controller?.measurements;
    if (measurements != null) _subscriptions.add(measurements.listen(_onMeasurement, onError: (Object _) {}));

    final ecg = _ecgStream();
    if (ecg == null) {
      _ecgUnavailable = true;
    } else {
      _subscriptions.add(
        ecg.listen(
          (samples) {
            _ecg.push(samples);
            _gotData();
          },
          onError: (Object error) {
            warning('$runtimeType - ECG stream error: $error');
            if (mounted) setState(() => _ecgUnavailable = true);
          },
        ),
      );
    }
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {
        _quietSeconds++;
        _hrAgeSeconds++;
      }),
    );
  }

  // ponytail: Polar opens a second ECG stream; clashes if the protocol samples polar.ecg too.
  /// ECG in millivolts: Movesense raw LSB is 0.38147 µV, Polar sends µV.
  Stream<List<double>>? _ecgStream() => switch (widget.device.deviceManager) {
    MovesenseDeviceManager(:final device?) => device.ecg.map((e) => [for (final s in e.samples) s * 0.00038147]),
    // Only the H10 streams ECG - a Verity Sense or H9 shows 'ECG not available'.
    PolarDeviceManager(:final polarIdentifier?, :final dataTypes?) && final polar
        when dataTypes.any((type) => type.name == 'ecg') =>
      polar.polar.startEcgStreaming(polarIdentifier).map((e) => [for (final s in e.samples) s.voltage / 1000]),
    _ => null,
  };

  void _onMeasurement(Measurement measurement) {
    switch (measurement.data) {
      case MovesenseHR(:final hr, :final rr) when _isMovesense:
        _beat(hr, rr);
      case PolarHR(:final samples) when !_isMovesense && samples.isNotEmpty:
        final sample = samples.last;
        final offSkin = sample.contactStatusSupported && !sample.contactStatus;
        _beat(offSkin ? 0 : sample.hr.toDouble(), sample.rrsMs.lastOrNull);
      case MovesenseStateChange(state: MovesenseDeviceState.tap) when _isMovesense:
        _tapFlash.forward(from: 0);
        setState(() {
          _taps++;
          _gotData();
        });
    }
  }

  void _beat(double bpm, int? rr) {
    if (bpm > 0) _heart.forward(from: 0);
    setState(() {
      _bpm = bpm > 0 ? bpm : null; // 0 = no skin contact
      _rr = rr ?? _rr;
      if (bpm > 0) _hrAgeSeconds = 0;
      _gotData();
    });
  }

  void _gotData() {
    _hasData = true;
    _quietSeconds = 0;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _clock?.cancel();
    _sweep.dispose();
    _heart.dispose();
    _tapFlash.dispose();
    _ecg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    String t(String key) => locale.translate('pages.connections.live.$key');
    final status = _status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xff101814), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _heart.drive(Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOut))),
                    child: const Icon(Icons.favorite, color: CarpSphereMorph.red, size: 36),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    (_hrStale ? null : _bpm)?.round().toString() ?? t('na'),
                    style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w700, height: 1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    locale.translate('cards.heartrate.bpm'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _statusPill(
                    switch (status) {
                      _LiveStatus.connecting => locale.translate('pages.connections.status.connecting'),
                      _ => t('status.${status.name}'),
                    },
                    switch (status) {
                      _LiveStatus.live => _green,
                      _LiveStatus.connecting => Colors.white54,
                      _LiveStatus.silent => const Color(0xffEB4B62),
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _EcgPainter(_ecg, _green)),
                    if (_ecg.isEmpty)
                      Center(
                        child: Text(
                          t(_ecgUnavailable ? 'ecg_unavailable' : 'status.waiting'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _stat(t('rr'), _hrStale || _rr == null ? t('na') : '$_rr ms')),
                  if (_isMovesense) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _tapFlash,
                        builder: (context, _) => _stat(
                          t('taps'),
                          '$_taps',
                          highlight: Color.lerp(_green.withValues(alpha: 0.5), Colors.transparent, _tapFlash.value),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          status == _LiveStatus.silent ? t('no_data') : (_isMovesense ? t('tap_hint') : ''),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: status == _LiveStatus.silent ? const Color(0xffEB4B62) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _statusPill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _stat(String label, String value, {Color? highlight}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: highlight ?? Colors.transparent,
      border: Border.all(color: Colors.white12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// A 4 s ECG buffer written like a bedside monitor: a head sweeps left to right,
/// overwriting the oldest samples, with a short blank gap ahead of it.
///
/// Sensors send ECG in batches (Movesense ~16 samples, ~8/s), so samples are queued
/// and drawn at the sensor [rate] each frame - the trace sweeps instead of jumping.
class _EcgSweep extends ChangeNotifier {
  _EcgSweep(this.rate) : values = List.filled(rate * 4, double.nan);

  final int rate;
  final List<double> values;
  final _pending = Queue<double>();
  Duration _last = Duration.zero;
  double _due = 0;
  int head = 0;
  bool isEmpty = true;

  void push(List<double> samples) => _pending.addAll(samples);

  /// Called every frame with the time since the sweep started.
  void advance(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    if (_pending.isEmpty) {
      _due = 0;
      return;
    }
    _due += dt.inMicroseconds * rate / Duration.microsecondsPerSecond;
    // The phone and sensor clocks drift - catch up once the queue passes half a second.
    final n = min(_pending.length, _due.floor() + max(0, _pending.length - rate ~/ 2));
    if (n == 0) return;
    _due -= _due.floor();
    final gap = values.length ~/ 30;
    for (var i = 0; i < n; i++) {
      values[head] = _pending.removeFirst();
      head = (head + 1) % values.length;
      values[(head + gap) % values.length] = double.nan;
    }
    isEmpty = false;
    notifyListeners();
  }
}

/// Draws the ECG at a fixed gain, like a bedside monitor: [halfRangeMv] above and below
/// the baseline, so a strap that is not worn shows a flat line instead of amplified noise.
class _EcgPainter extends CustomPainter {
  _EcgPainter(this.sweep, this.color) : super(repaint: sweep);

  /// Chest-strap QRS peaks are about 1-2 mV; 0.5 mV per grid line.
  static const halfRangeMv = 1.5;

  final _EcgSweep sweep;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += size.width / 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final values = sweep.values;
    final present = values.where((v) => !v.isNaN);
    if (present.isEmpty) return;
    // Only the offset follows the signal (electrode DC offset and drift); the gain is fixed.
    final baseline = present.reduce((a, b) => a + b) / present.length;
    final dx = size.width / (values.length - 1);
    double y(double v) => size.height / 2 * (1 - ((v - baseline) / halfRangeMv).clamp(-1.0, 1.0));

    final path = Path();
    var drawing = false;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v.isNaN || i == sweep.head) {
        drawing = false;
        continue;
      }
      drawing ? path.lineTo(i * dx, y(v)) : path.moveTo(i * dx, y(v));
      drawing = true;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // The glowing dot at the sweep head.
    final i = (sweep.head - 1) % values.length;
    if (!values[i].isNaN) canvas.drawCircle(Offset(i * dx, y(values[i])), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => false;
}
