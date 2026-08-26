part of carp_study_app;

class SleepCardViewModel extends SerializableViewModel<WeeklySleep> {
  @override
  WeeklySleep createModel() => WeeklySleep();

  /// Sleep streams under the Health Service role, not the phone's.
  String? get deviceRoleName => roleOf(HealthService.DEVICE_TYPE);

  /// Any sleep in the last 7 nights? The page hides an all-empty card.
  bool get hasData => nights.any((night) => night.minutes > 0);

  /// The 7 nights ending today, oldest first.
  List<DailySleep> get nights => model.last7Days();

  /// Real sleep stages, deepest first - disjoint spans, so they can be summed.
  static const List<String> sleepStageTypes = ['SLEEP_DEEP', 'SLEEP_LIGHT', 'SLEEP_REM'];

  /// Unstaged sleep (iPhone ASLEEP, Health Connect SESSION), most precise
  /// first - fallbacks spanning the same night, not something to add on top.
  static const List<String> unstagedTypes = ['SLEEP_ASLEEP', sleepSessionType];

  /// A whole sleep session, bedtime to wake-up.
  static const String sleepSessionType = 'SLEEP_SESSION';

  /// All sleep types to request - the probe drops unsupported ones per platform.
  static const Set<String> sleepDataTypes = {...sleepStageTypes, ...unstagedTypes};

  /// Stream of health measurements carrying sleep.
  Stream<Measurement>? get sleepEvents =>
      controller?.measurements.where((measurement) => _minutesOf(measurement.data) != null);

  /// The minutes of sleep in [data], or null if it is not a sleep reading.
  static double? _minutesOf(Data data) {
    if (data is! HealthData || !sleepDataTypes.contains(data.healthDataType)) return null;
    final value = data.value;
    return value is NumericHealthValue ? value.numericValue.toDouble() : null;
  }

  /// The morning [data] is charted on - a night spans midnight, so split the
  /// day at noon. ponytail: splits shift workers sleeping across midday.
  static DateTime _nightOf(HealthData data) {
    final end = data.dateTo.toLocal();
    return end.hour < 12 ? end : end.add(const Duration(days: 1));
  }


  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    sleepEvents?.listen((measurement) {
      _record(model, measurement);
      notifyListeners();
    }, onError: onMeasurementStreamError);
  }

  /// Fold [measurement] into [into], if it carries sleep.
  static void _record(WeeklySleep into, Measurement measurement) {
    final data = measurement.data;
    final minutes = _minutesOf(data);
    if (minutes == null) return;
    into.addSleep(_nightOf(data as HealthData), minutes, type: data.healthDataType);
  }

  /// Recompute the trailing 7 nights from backfilled [measurements] -
  /// idempotent, so refreshing never double-counts.
  void addMeasurements(List<Measurement> measurements) {
    model.clearSleep();
    for (final measurement in measurements) {
      _record(model, measurement);
    }
    notifyListeners();
  }
}

/// Sleep minutes organized by the night they belong to.
@JsonSerializable(includeIfNull: false)
class WeeklySleep extends DataModel {
  /// Minutes per night (keyed "2026-08-21", the waking morning) per sleep type.
  Map<String, Map<String, double>> nightlyMinutes = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Add [minutes] of [type] to the night of [date]. A night arrives as many
  /// readings - several per stage, or one per session on a night with
  /// wake-ups - so readings of the same type accumulate.
  void addSleep(DateTime date, double minutes, {required String type}) {
    final night = nightlyMinutes.putIfAbsent(_dayKey(date), () => {});
    night[type] = (night[type] ?? 0) + minutes;
  }

  void clearSleep() => nightlyMinutes.clear();

  /// Minutes per [SleepCardViewModel.sleepStageTypes] plus one unstaged
  /// segment - sources overlap, so only the most detailed one is used.
  List<double> segmentsOn(DateTime date) {
    final night = nightlyMinutes[_dayKey(date)] ?? const <String, double>{};
    final stages = [for (final stage in SleepCardViewModel.sleepStageTypes) night[stage] ?? 0];
    if (stages.any((minutes) => minutes > 0)) return [...stages, 0];

    final unstaged = SleepCardViewModel.unstagedTypes.map((type) => night[type] ?? 0);
    return [...stages.map((_) => 0.0), unstaged.firstWhere((minutes) => minutes > 0, orElse: () => 0)];
  }

  /// Minutes asleep on the night of [date].
  double minutesOn(DateTime date) => segmentsOn(date).fold<double>(0, (sum, minutes) => sum + minutes);

  /// Sleep for the 7 nights ending on [today] (defaults to now), oldest
  /// first - zero for any night with nothing recorded. Today is always last.
  List<DailySleep> last7Days({DateTime? today}) {
    final end = today ?? DateTime.now();
    return List.generate(7, (i) {
      final date = end.subtract(Duration(days: 6 - i));
      return DailySleep(date, minutesOn(date));
    });
  }

  @override
  WeeklySleep fromJson(Map<String, dynamic> json) => _$WeeklySleepFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeeklySleepToJson(this);
}

/// Sleep for the night ending on the morning of [date].
class DailySleep {
  final DateTime date;

  /// Minutes asleep that night.
  final double minutes;

  DailySleep(this.date, this.minutes);

  /// Hours asleep that night, for display.
  double get hours => minutes / 60;
}
