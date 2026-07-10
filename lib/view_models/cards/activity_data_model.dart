part of carp_study_app;

class ActivityCardViewModel extends SerializableViewModel<WeeklyActivities> {
  Measurement _lastActivity = Measurement.fromData(Activity(type: ActivityType.STILL, confidence: 100));

  @override
  WeeklyActivities createModel() => WeeklyActivities();
  Map<ActivityType, Map<int, int>> get activities => model.activities;
  List<DailyActivity> activitiesByType(ActivityType type) => model.activitiesByType(type);

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
      var lastActivity = _lastActivity;

      if ((measurement.data as Activity).type != (lastActivity.data as Activity).type) {
        // if we have a new type of activity
        // add the minutes to the last known activity type
        DateTime start = DateTime.fromMicrosecondsSinceEpoch(lastActivity.sensorStartTime);
        DateTime end = DateTime.fromMicrosecondsSinceEpoch(measurement.sensorStartTime);
        model.increaseActivityDuration(
          (lastActivity.data as Activity).type,
          start.weekday,
          end.difference(start).inMinutes,
        );
        // and then save the new activity
        _lastActivity = measurement;
      }
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
