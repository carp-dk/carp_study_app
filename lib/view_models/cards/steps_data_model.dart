part of carp_study_app;

class StepsCardViewModel extends SerializableViewModel<WeeklySteps> {
  int? _lastStep;

  @override
  WeeklySteps createModel() => WeeklySteps();

  /// Whether any steps were recorded in the last 7 days - hides an empty card.
  bool get hasData => steps.any((day) => day.steps > 0);

  /// Steps for the last 7 days ending today, oldest first.
  List<DailySteps> get steps => model.last7Days();

  /// Largest believable growth between two readings (~4 h of fast walking) -
  /// a reboot resets the pedometer total, making deltas across it bogus.
  static const int _maxCredibleDelta = 20000;

  /// Fold [measurement] into [into] and return it as the new previous reading.
  /// The pedometer reports a running total: a day's steps are the growth since
  /// [previous]; a lower or implausibly large delta means a reset, not steps.
  static int? _addStepCount(WeeklySteps into, Measurement measurement, int? previous) {
    final steps = _stepsOf(measurement.data)!;
    final delta = previous == null ? null : steps - previous;
    if (delta != null && delta >= 0 && delta <= _maxCredibleDelta) {
      into.increaseStepCount(measurement.sensorTime, delta);
    }
    return steps;
  }

  /// The pedometer's running total in [data], or null if not a pedometer
  /// reading - [StepCount] (API < 2.0) and [StepEvent] carry the same total.
  static int? _stepsOf(Data data) => switch (data) {
    StepCount(:final steps) => steps,
    StepEvent(:final steps) => steps,
    _ => null,
  };


  /// The pedometer measure types, newest first - a protocol declares one of them.
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

  /// Recompute the trailing 7 days from backfilled [measurements] -
  /// idempotent. Baseline resets at each day boundary: the pedometer total
  /// is not continuous across midnight.
  void addMeasurements(List<Measurement> measurements) {
    model.dailySteps.clear();
    final sorted = [...measurements]..sort((a, b) => a.sensorTime.compareTo(b.sensorTime));
    int? previous;
    DateTime? previousDate;
    for (final measurement in sorted) {
      final date = measurement.sensorTime;
      if (previousDate != null && !_isSameDay(date, previousDate)) previous = null;
      previousDate = date;
      previous = _addStepCount(model, measurement, previous);
    }
    // Resync the live baseline, or the next live tick re-adds backfilled deltas.
    if (previous != null) _lastStep = previous;
    notifyListeners();
  }

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Steps organized by calendar day.
@JsonSerializable(includeIfNull: false)
class WeeklySteps extends DataModel {
  /// Steps per calendar day, keyed by [_dayKey] (e.g. "2026-08-21").
  Map<String, int> dailySteps = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void increaseStepCount(DateTime date, int steps) =>
      dailySteps[_dayKey(date)] = (dailySteps[_dayKey(date)] ?? 0) + steps;

  /// Steps for the 7 days ending on [today] (defaults to now), oldest first.
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
