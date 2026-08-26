part of carp_study_app;

class StepsCardViewModel extends SerializableViewModel<WeeklySteps> {
  int? _lastStep;

  @override
  WeeklySteps createModel() => WeeklySteps();

  /// Whether any steps were recorded in the last 7 days - the page hides an
  /// all-zero chart.
  bool get hasData => steps.any((day) => day.steps > 0);

  /// Steps for the last 7 days, ending today - oldest first, so today is
  /// always the last (rightmost) entry regardless of which weekday it is.
  List<DailySteps> get steps => model.last7Days();

  /// The largest believable growth between two consecutive readings. A
  /// reboot restarts the pedometer's running total, so readings from before
  /// and after it belong to different counting epochs; a delta across that
  /// boundary is an artifact, not steps. ~4 h of sustained fast walking.
  static const int _maxCredibleDelta = 20000;

  /// Fold [measurement] into [into] and return it as the new previous reading.
  ///
  /// A pedometer reports a running total, so a day's steps are the growth since
  /// the last reading - the first reading only establishes a baseline. That
  /// total resets to ~0 on a phone reboot or app reinstall, so a lower reading
  /// than [previous] is not a negative number of steps - it is a new baseline.
  /// The jump back up to the pre-reset series is equally bogus, hence the
  /// [_maxCredibleDelta] ceiling.
  static int? _addStepCount(WeeklySteps into, Measurement measurement, int? previous) {
    final steps = _stepsOf(measurement.data)!;
    final delta = previous == null ? null : steps - previous;
    if (delta != null && delta >= 0 && delta <= _maxCredibleDelta) {
      into.increaseStepCount(measurement.dateTime, delta);
    }
    return steps;
  }

  /// The pedometer's running total in [data], or null if it is not a
  /// pedometer reading. Protocols at API level < 2.0 report [StepCount],
  /// newer ones [StepEvent] - the same total under two names.
  static int? _stepsOf(Data data) => switch (data) {
    StepCount(:final steps) => steps,
    StepEvent(:final steps) => steps,
    _ => null,
  };

  DateTime get _startOfWindow => DateTime.now().subtract(const Duration(days: 6));

  String get startOfWeek => DateFormat('dd').format(_startOfWindow);

  String get endOfWeek => DateFormat('dd').format(DateTime.now());

  String get currentMonth => DateFormat('MMM').format(_startOfWindow);

  String get nextMonth => DateFormat('MMM').format(DateTime.now());

  String get currentYear => DateFormat('yyyy').format(DateTime.now());

  /// The pedometer measure types, newest first. A protocol declares one of
  /// them: API 2.0 uses [SensorSamplingPackage.STEP_EVENT], 1.x the
  /// deprecated [CarpDataTypes.STEP_COUNT]. Both carry the same running total.
  static const List<String> dataTypes = [SensorSamplingPackage.STEP_EVENT, CarpDataTypes.STEP_COUNT];

  /// Stream of pedometer (step) [DataPoint] measures.
  Stream<Measurement>? get pedometerEvents =>
      controller?.measurements.where((measurement) => _stepsOf(measurement.data) != null);

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    // listen for pedometer events and count them
    pedometerEvents?.listen((measurement) {
      _lastStep = _addStepCount(model, measurement, _lastStep);
    }, onError: onMeasurementStreamError);
  }

  /// Recompute the trailing 7 days of steps from backfilled [measurements],
  /// replacing whatever this call previously computed - safe to call again on
  /// every refresh without double-counting.
  ///
  /// Measurements arrive as one flat list across the window; sort them and
  /// reset the running baseline at each day boundary so a delta is never
  /// computed across midnight - the pedometer total is not continuous there.
  void addMeasurements(List<Measurement> measurements) {
    model.dailySteps.clear();
    final sorted = [...measurements]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    int? previous;
    DateTime? previousDate;
    for (final measurement in sorted) {
      final date = measurement.dateTime;
      if (previousDate != null && !_isSameDay(date, previousDate)) previous = null;
      previousDate = date;
      previous = _addStepCount(model, measurement, previous);
    }
    // Resync the live stream's baseline to the freshest backfilled reading -
    // otherwise the next live tick diffs against stale state from before
    // this refresh and re-adds an already-backfilled delta on top, which
    // compounds into a huge total across repeated refreshes.
    if (previous != null) _lastStep = previous;
    notifyListeners();
  }

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Steps organized by calendar day.
@JsonSerializable(includeIfNull: false)
class WeeklySteps extends DataModel {
  /// Steps per calendar day, keyed by [_dayKey] (e.g. "2026-08-21") - an
  /// absolute date rather than a weekday, so a reading always lands on the
  /// day it was actually taken regardless of which day of the week is "now".
  Map<String, int> dailySteps = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void increaseStepCount(DateTime date, int steps) =>
      dailySteps[_dayKey(date)] = (dailySteps[_dayKey(date)] ?? 0) + steps;

  /// Steps for the 7 days ending on [today] (defaults to now), oldest first -
  /// a zero for any day with nothing recorded. Today is always last, so the
  /// freshest data is always on the right of the chart.
  List<DailySteps> last7Days({DateTime? today}) {
    final end = today ?? DateTime.now();
    return List.generate(7, (i) {
      final date = end.subtract(Duration(days: 6 - i));
      return DailySteps(date, dailySteps[_dayKey(date)] ?? 0);
    });
  }

  @override
  String toString() {
    String str = ' date | steps\n';
    dailySteps.forEach((day, steps) => str += ' $day | $steps\n');
    return str;
  }

  @override
  WeeklySteps fromJson(Map<String, dynamic> json) => _$WeeklyStepsFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeeklyStepsToJson(this);
}

/// Steps for one calendar [date].
class DailySteps {
  final DateTime date;
  final int steps;

  DailySteps(this.date, this.steps);
}
