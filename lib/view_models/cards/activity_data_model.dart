part of carp_study_app;

class ActivityCardViewModel extends SerializableViewModel<WeeklyActivities> {
  Measurement _lastActivity = Measurement.fromData(Activity(type: ActivityType.STILL, confidence: 100));

  @override
  WeeklyActivities createModel() => WeeklyActivities();

  Map<ActivityType, Map<int, int>> get activities => (_hasActivity ? model : _demo).activities;

  List<DailyActivity> activitiesByType(ActivityType type) =>
      (activities[type] ?? const {}).entries.map((entry) => DailyActivity(entry.key, entry.value)).toList();

  bool get _hasActivity =>
      !AppConfig.useDemoChartData ||
      model.activities.values.any((perDay) => perDay.values.any((minutes) => minutes > 0));

  /// The demo week, folded together by the same code that folds live readings.
  late final WeeklyActivities _demo = _aggregate(DemoChartData.activityMeasurements);

  static WeeklyActivities _aggregate(List<Measurement> measurements) {
    final into = WeeklyActivities();
    Measurement? previous;
    for (final measurement in measurements) {
      previous = _addActivity(into, measurement, previous);
    }
    return into;
  }

  /// Fold [measurement] into [into] and return it as the new previous reading.
  ///
  /// The probe reports the activity it currently sees, so a duration is the gap
  /// until a *different* activity is reported.
  static Measurement? _addActivity(WeeklyActivities into, Measurement measurement, Measurement? previous) {
    if (previous == null) return measurement;
    if ((measurement.data as Activity).type == (previous.data as Activity).type) return previous;

    final start = previous.dateTime;
    into.increaseActivityDuration(
      (previous.data as Activity).type,
      start.weekday,
      measurement.dateTime.difference(start).inMinutes,
    );
    return measurement;
  }

  /// Stream of activity measurements.
  Stream<Measurement>? get activityEvents =>
      controller?.measurements.where((measurement) => measurement.data is Activity);

  final DateTime _startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  final DateTime _endOfWeek = DateTime.now()
      .subtract(Duration(days: DateTime.now().weekday - 1))
      .add(Duration(days: 6));

  String get startOfWeek => DateFormat('dd').format(_startOfWeek);

  String get endOfWeek => DateFormat('dd').format(_endOfWeek);

  String get currentMonth => DateFormat('MMM').format(DateTime(_startOfWeek.year, _startOfWeek.month));

  String get nextMonth => DateFormat('MMM').format(DateTime(_startOfWeek.year, _startOfWeek.month + 1, 1));

  String get currentYear => DateFormat('yyyy').format(DateTime(DateTime.now().year));

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    // listen for activity events and count the minutes
    activityEvents?.listen((measurement) {
      _lastActivity = _addActivity(model, measurement, _lastActivity) ?? measurement;
    }, onError: onMeasurementStreamError);
  }
}

/// Weekly activities in minutes organized by type.
@JsonSerializable(includeIfNull: false)
class WeeklyActivities extends DataModel {
  /// A map of activities organized first by type and then by day of week.
  ///
  ///   (type,weekday,minutes)
  ///
  /// In accordance with Dart [DateTime] a week starts with Monday,
  /// which has the value 1.
  Map<ActivityType, Map<int, int>> activities = {};

  /// A list of activities of a specific [type].
  List<DailyActivity> activitiesByType(ActivityType type) =>
      activities[type]!.entries.map((entry) => DailyActivity(entry.key, entry.value)).toList();

  WeeklyActivities() {
    // initialize every week or if is the first time opening the app
    for (var type in ActivityType.values) {
      activities[type] = {};
      for (int i = 1; i <= 7; i++) {
        activities[type]![i] = 0;
      }
    }
  }

  /// Increase the number of minutes of doing [activityType] on [weekday] with [minutes].
  void increaseActivityDuration(ActivityType activityType, int weekday, int minutes) {
    activities[activityType]![weekday] = (activities[activityType]![weekday] ?? 0) + minutes;
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

/// An activity of a specific type for a specific week day [1..7] and
/// the number of active minutes that day.
class DailyActivity extends DailyMeasure {
  final int minutes;
  ActivityType? type;

  /// Activity [type] as a string.
  String get typeString => type.toString().split(".").last;

  DailyActivity(super.weekday, this.minutes);
}
