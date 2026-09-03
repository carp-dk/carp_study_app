part of carp_study_app;

/// Generated sensor data for demos and promo videos: a week of history on the
/// statistics cards, plus fresh measurements every [interval] so the cards move
/// on screen. Enabled with `--dart-define=demo=true`, off otherwise.
///
/// Feeds the same paths real sensors do - [measurements] stands in for the
/// study controller's stream, and the week is handed to the cards'
/// `addMeasurements`, so nothing about the cards themselves is demo-aware.
class DemoDataService {
  static final DemoDataService _instance = DemoDataService._();
  factory DemoDataService() => _instance;
  DemoDataService._();

  /// How often live measurements are generated.
  static const Duration interval = Duration(seconds: 5);

  /// The measures this generator stands in for, so their cards show up even
  /// when the deployment collects none of them. Movesense is left out - one
  /// heart rate card, not two showing the same beats.
  static const Set<String> demoMeasures = {
    PolarSamplingPackage.HR,
    SensorSamplingPackage.STEP_EVENT,
    ContextSamplingPackage.ACTIVITY,
    ContextSamplingPackage.MOBILITY,
    HealthSamplingPackage.HEALTH,
  };

  /// Whether the generator produces [type] in place of a real sensor.
  static bool covers(String type) => AppConfig.demoMode && demoMeasures.contains(type);

  /// Fixed seed - every take of the promo video shows the same data.
  final Random _random = Random(42);

  final StreamController<Measurement> _measurements = StreamController.broadcast();
  Timer? _timer;

  /// The generated live measurements, standing in for the sensor streams.
  Stream<Measurement> get measurements => _measurements.stream;

  /// Today's running totals, continued by the live ticks so the figures only
  /// grow from where the backfilled week left them.
  int _steps = 0;
  double _distance = 0;
  int _places = 3;
  double _homeStay = 0.5;

  /// Fill [model]'s cards with the last week and start the live stream.
  /// Idempotent - a second call is a no-op, so revisiting the page never wipes
  /// what the live ticks have added.
  void start(StatisticsViewModel model) {
    if (_timer != null) return;
    final now = DateTime.now();

    model.polarHeartRateCardDataModel.addMeasurements(_heartRates(now));
    model.stepsCardDataModel.addMeasurements(_stepCounts(now));
    model.activityCardDataModel.addMeasurements(_activities(now));
    model.mobilityCardDataModel.addMeasurements(_mobility(now));
    model.sleepCardDataModel.addMeasurements(_sleep(now));

    _timer = Timer.periodic(interval, (_) => tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Emit one round of live measurements: a heart beat, a few more steps and a
  /// little more distance travelled today.
  ///
  /// ponytail: no activity here - the card measures an activity by the gap to
  /// the next, *different* one, so ticks 5 s apart would all be 0 minutes.
  void tick() {
    final now = DateTime.now();
    _steps += 5 + _random.nextInt(25);
    _distance += 20 + _random.nextInt(60);

    _measurements.add(_at(now, PolarHR(samples: [_hrSample(_bpm(now))])));
    _measurements.add(_at(now, StepEvent(steps: _steps)));
    _measurements.add(_at(now, _mobilityOn(DateUtils.dateOnly(now))));
  }

  /// A measurement of [data] taken [at] - the sensor time the cards bucket by.
  Measurement _at(DateTime at, Data data) => Measurement.fromData(data, at.microsecondsSinceEpoch);

  /// Midnight of the 7 days ending today, oldest first.
  List<DateTime> _week(DateTime now) =>
      List.generate(7, (i) => DateUtils.dateOnly(now).subtract(Duration(days: 6 - i)));

  /// A plausible heart rate at [at]: a resting baseline dipping at night and
  /// peaking mid-afternoon, with an evening workout on top.
  double _bpm(DateTime at) {
    final hour = at.hour + at.minute / 60;
    final workout = (hour >= 17.5 && hour < 18.5) ? 45 : 0;
    return (62 + 12 * sin((hour - 8) / 24 * 2 * pi) + workout + _random.nextInt(9) - 4).roundToDouble();
  }

  PolarHRSample _hrSample(double bpm) =>
      PolarHRSample(hr: bpm.round(), rrsMs: [(60000 / bpm).round()], contactStatus: true, contactStatusSupported: true);

  /// A heart rate every 15 minutes of the last week, up to now.
  List<Measurement> _heartRates(DateTime now) => [
    for (final at in _every(const Duration(minutes: 15), from: _week(now).first, until: now))
      _at(at, PolarHR(samples: [_hrSample(_bpm(at))])),
  ];

  /// The waking day the step and activity generators fill in.
  static const Duration _wakeUp = Duration(hours: 7);
  static const Duration _bedTime = Duration(hours: 23);

  /// The pedometer's running total every half hour of the waking day. The total
  /// is only meaningful within a day - the card resets its baseline at midnight,
  /// as a real pedometer does on reboot.
  List<Measurement> _stepCounts(DateTime now) => [
    for (final day in _week(now))
      for (final at in _every(
        const Duration(minutes: 30),
        from: day.add(_wakeUp),
        until: _earliest(day.add(_bedTime), now),
      ))
        _at(at, StepEvent(steps: _steps += 100 + _random.nextInt(500))),
  ];

  /// A day of activity transitions, as minutes spent doing each - the card
  /// times an activity by the gap to the next one, so every entry both ends the
  /// previous activity and starts its own.
  static const List<(ActivityType, int)> _dayPlan = [
    (ActivityType.STILL, 0),
    (ActivityType.WALKING, 25),
    (ActivityType.STILL, 220),
    (ActivityType.ON_BICYCLE, 20),
    (ActivityType.STILL, 90),
    (ActivityType.RUNNING, 35),
    (ActivityType.STILL, 60),
    (ActivityType.WALKING, 30),
    (ActivityType.STILL, 0),
  ];

  List<Measurement> _activities(DateTime now) {
    final measurements = <Measurement>[];
    for (final day in _week(now)) {
      var at = day.add(_wakeUp + const Duration(minutes: 30));
      for (final (type, minutes) in _dayPlan) {
        at = at.add(Duration(minutes: minutes));
        if (at.isAfter(now)) break;
        measurements.add(_at(at, Activity(type: type, confidence: 100)));
      }
    }
    return measurements;
  }

  /// One mobility summary per day - the card keeps the latest reading per day,
  /// which the live ticks keep raising for today.
  List<Measurement> _mobility(DateTime now) {
    final measurements = <Measurement>[];
    for (final day in _week(now)) {
      _places = 2 + _random.nextInt(5);
      _homeStay = 0.35 + _random.nextInt(40) / 100;
      _distance = 3000 + _random.nextInt(12000).toDouble();
      measurements.add(_at(_earliest(day.add(_bedTime), now), _mobilityOn(day)));
    }
    return measurements;
  }

  Mobility _mobilityOn(DateTime date) => Mobility(
    date: date,
    numberOfStops: _places + 2,
    numberOfMoves: _places,
    numberOfPlaces: _places,
    homeStay: _homeStay,
    distanceTraveled: _distance,
  );

  /// A night's sleep per day, in stages, ending on the morning it is charted
  /// on - tonight's sleep has not happened yet, so the week ends yesterday.
  List<Measurement> _sleep(DateTime now) => [
    for (final morning in _week(now).map((day) => day.add(_wakeUp)))
      if (morning.isBefore(now))
        for (final (type, minutes) in [
          ('SLEEP_DEEP', 70 + _random.nextInt(40)),
          ('SLEEP_LIGHT', 200 + _random.nextInt(60)),
          ('SLEEP_REM', 60 + _random.nextInt(40)),
        ])
          _at(
            morning,
            HealthData(
              uuid: '$type-${morning.toIso8601String()}',
              value: NumericHealthValue(numericValue: minutes),
              unit: 'MINUTES',
              healthDataType: type,
              dateFrom: morning.subtract(Duration(minutes: minutes)),
              dateTo: morning,
              platform: HealthPlatform.APPLE_HEALTH,
            ),
          ),
  ];

  /// Every [step] from [from] up to [until], exclusive.
  Iterable<DateTime> _every(Duration step, {required DateTime from, required DateTime until}) sync* {
    for (var at = from; at.isBefore(until); at = at.add(step)) {
      yield at;
    }
  }

  static DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
