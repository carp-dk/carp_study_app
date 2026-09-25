part of carp_study_app;

class SleepCardViewModel extends SerializableViewModel<WeeklySleep> {
  @override
  WeeklySleep createModel() => WeeklySleep();

  /// Any sleep in the last 7 nights? The page hides an all-empty card.
  bool get hasData => nights.any((night) => night.minutes > 0);

  /// The 7 nights ending today, oldest first.
  List<DailySleep> get nights => model.last7Days();

  /// Real sleep stages, deepest first - disjoint spans, so they can be summed.
  static const List<String> sleepStageTypes = ['SLEEP_DEEP', 'SLEEP_LIGHT', 'SLEEP_REM'];

  /// Unstaged time asleep (iPhone), and a whole sleep from bedtime to wake-up (Health Connect).
  static const String asleepType = 'SLEEP_ASLEEP';
  static const String sessionType = 'SLEEP_SESSION';

  /// Time awake within a sleep - derived, never requested.
  static const String awakeType = 'SLEEP_AWAKE';

  /// All sleep types to request - the probe drops unsupported ones per platform.
  static const Set<String> sleepDataTypes = {...sleepStageTypes, asleepType, sessionType};

  /// The segments of a night, bottom to top of its bar.
  static const List<String> segmentTypes = [...sleepStageTypes, asleepType, awakeType];

  /// Sleep readings by record, so the probe and backfill never double-count.
  final Map<String, HealthData> _readings = {};

  /// Stream of health measurements carrying sleep.
  Stream<Measurement>? get sleepEvents => controller?.measurements.where((measurement) => _isSleep(measurement.data));

  static bool _isSleep(Data data) => data is HealthData && sleepDataTypes.contains(data.healthDataType);

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _readings.clear();

    sleepEvents?.listen((measurement) {
      _add(measurement.data);
      model.setSleep(_readings.values);
      notifyListeners();
    }, onError: onMeasurementStreamError);
  }

  void _add(Data data) {
    if (!_isSleep(data)) return;
    data as HealthData;
    _readings['${data.uuid}|${data.healthDataType}|${data.dateFrom}|${data.dateTo}'] = data;
  }

  /// Recompute from backfilled [measurements] - replaces, so refreshing never double-counts.
  void addMeasurements(List<Measurement> measurements) {
    _readings.clear();
    for (final measurement in measurements) {
      _add(measurement.data);
    }
    model.setSleep(_readings.values);
    notifyListeners();
  }
}

/// Sleep minutes organized by the day it ended on.
@JsonSerializable(includeIfNull: false)
class WeeklySleep extends DataModel {
  /// Readings less than this apart are one sleep, e.g. waking up at night.
  static const Duration maxGap = Duration(hours: 2);

  /// Minutes per day (keyed "2026-08-21", the waking day) per [SleepCardViewModel.segmentTypes].
  Map<String, Map<String, double>> nightlyMinutes = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Add [minutes] of [type] to the day of [date].
  void addSleep(DateTime date, double minutes, {required String type}) {
    final night = nightlyMinutes.putIfAbsent(_dayKey(date), () => {});
    night[type] = (night[type] ?? 0) + minutes;
  }

  void clearSleep() => nightlyMinutes.clear();

  /// Rebuild from raw sleep [readings]. Readings less than [maxGap] apart are
  /// one sleep, counted on the day it ends, from bedtime to wake-up - so
  /// 21:00 to 07:00 is 10 h on the waking day, and a nap adds to its own day.
  void setSleep(Iterable<HealthData> readings) {
    clearSleep();
    final sorted = readings.toList()..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    var sleep = <HealthData>[];
    DateTime? end;
    for (final reading in sorted) {
      if (end != null && reading.dateFrom.difference(end) > maxGap) {
        _addSleep(sleep, end);
        sleep = [];
        end = null;
      }
      sleep.add(reading);
      if (end == null || reading.dateTo.isAfter(end)) end = reading.dateTo;
    }
    if (end != null) _addSleep(sleep, end);
  }

  /// Split one sleep into stages, unstaged sleep and the awake rest.
  void _addSleep(List<HealthData> sleep, DateTime end) {
    double minutes(String type) => sleep
        .where((reading) => reading.healthDataType == type)
        .fold(0.0, (sum, reading) => sum + reading.dateTo.difference(reading.dateFrom).inSeconds / 60);

    final total = end.difference(sleep.first.dateFrom).inSeconds / 60;
    final stages = {for (final type in SleepCardViewModel.sleepStageTypes) type: minutes(type)};
    final staged = stages.values.fold(0.0, (sum, value) => sum + value);

    // Stages are the most detailed; else time asleep; else the sessions themselves.
    final asleep = minutes(SleepCardViewModel.asleepType);
    final unstaged = staged > 0 ? 0.0 : min(total, asleep > 0 ? asleep : minutes(SleepCardViewModel.sessionType));

    final day = end.toLocal();
    final segments = {
      ...stages,
      SleepCardViewModel.asleepType: unstaged,
      SleepCardViewModel.awakeType: max(0.0, total - staged - unstaged),
    };
    segments.forEach((type, value) {
      if (value > 0) addSleep(day, value, type: type);
    });
  }

  /// Minutes per [SleepCardViewModel.segmentTypes] on the day of [date].
  List<double> segmentsOn(DateTime date) {
    final night = nightlyMinutes[_dayKey(date)] ?? const <String, double>{};
    return [for (final type in SleepCardViewModel.segmentTypes) night[type] ?? 0];
  }

  /// Minutes from bedtime to wake-up on the day of [date].
  double minutesOn(DateTime date) => segmentsOn(date).fold<double>(0, (sum, minutes) => sum + minutes);

  /// Sleep for the 7 days ending on [today] (defaults to now), oldest
  /// first - zero for any day with nothing recorded. Today is always last.
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

  /// Minutes from bedtime to wake-up.
  final double minutes;

  DailySleep(this.date, this.minutes);

  /// Hours, for display.
  double get hours => minutes / 60;
}
