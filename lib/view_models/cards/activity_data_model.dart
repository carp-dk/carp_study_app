part of carp_study_app;

class ActivityCardViewModel extends SerializableViewModel<WeeklyActivities> {
  Measurement _lastActivity = Measurement.fromData(Activity(type: ActivityType.STILL, confidence: 100));

  @override
  WeeklyActivities createModel() => WeeklyActivities();

  /// The activity types the card charts - STILL is tracked but not shown.
  static const List<ActivityType> chartedTypes = [ActivityType.WALKING, ActivityType.RUNNING, ActivityType.ON_BICYCLE];

  /// Whether any charted activity was recorded in the last 7 days - hides an
  /// empty card.
  bool get hasData => days.any((day) => chartedTypes.any((type) => minutesOn(type, day) > 0));

  /// The 7 days ending today, oldest first.
  List<DateTime> get days => model.last7Days();

  /// Minutes of [type] on [date].
  int minutesOn(ActivityType type, DateTime date) => model.minutesOn(type, date);

  /// Fold [measurement] into [into] and return it as the new previous reading -
  /// a duration is the gap until a *different* activity is reported.
  static Measurement? _addActivity(WeeklyActivities into, Measurement measurement, Measurement? previous) {
    if (previous == null) return measurement;
    if ((measurement.data as Activity).type == (previous.data as Activity).type) return previous;

    final start = previous.sensorTime;
    into.increaseActivityDuration(
      (previous.data as Activity).type,
      start,
      measurement.sensorTime.difference(start).inMinutes,
    );
    return measurement;
  }

  /// Stream of activity measurements.
  Stream<Measurement>? get activityEvents =>
      measurements?.where((measurement) => measurement.data is Activity);

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    // listen for activity events and count the minutes
    activityEvents?.listen((measurement) {
      _lastActivity = _addActivity(model, measurement, _lastActivity) ?? measurement;
    }, onError: onMeasurementStreamError);
  }

  /// Recompute this week's minutes from backfilled [measurements] -
  /// idempotent, with a per-day reset so activities never span midnight.
  void addMeasurements(List<Measurement> measurements) {
    model.activities.clear();
    final sorted = [...measurements]..sort((a, b) => a.sensorTime.compareTo(b.sensorTime));
    Measurement? previous;
    int? previousDay;
    for (final measurement in sorted) {
      if (previousDay != null && measurement.sensorTime.day != previousDay) previous = null;
      previousDay = measurement.sensorTime.day;
      previous = _addActivity(model, measurement, previous) ?? measurement;
    }
    notifyListeners();
  }
}

/// Activity minutes organized by type and calendar day.
@JsonSerializable(includeIfNull: false)
class WeeklyActivities extends DataModel {
  /// Minutes per activity type per calendar day, keyed by [_dayKey]
  /// (e.g. "2026-08-21").
  Map<ActivityType, Map<String, int>> activities = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Increase the minutes of doing [activityType] on [date] with [minutes].
  void increaseActivityDuration(ActivityType activityType, DateTime date, int minutes) {
    final byDay = activities[activityType] ??= {};
    byDay[_dayKey(date)] = (byDay[_dayKey(date)] ?? 0) + minutes;
  }

  /// Minutes of [type] on [date], zero if nothing was recorded.
  int minutesOn(ActivityType type, DateTime date) => activities[type]?[_dayKey(date)] ?? 0;

  /// The 7 days ending on [today] (defaults to now), oldest first.
  List<DateTime> last7Days({DateTime? today}) {
    final end = today ?? DateTime.now();
    return List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
  }

  @override
  WeeklyActivities fromJson(Map<String, dynamic> json) => _$WeeklyActivitiesFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeeklyActivitiesToJson(this);

  @override
  String toString() {
    String str = '  TYPE\t| day | min.\n';
    activities.forEach(
      (type, data) =>
          data.forEach((day, minutes) => str += '${type.toString().split(".").last}\t|  $day  |  $minutes\n'),
    );
    return str;
  }
}
