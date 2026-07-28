part of carp_study_app;

/// Placeholder measurements for the statistics charts, shown while a study has
/// collected nothing yet and only when [AppConfig.useDemoChartData] is on.
///
/// These are real CAMS [Measurement]s carrying the same [Data] types the
/// sampling packages emit - [StepCount], [PolarHR], [Activity] - each stamped
/// with the time it was "taken". The card view models aggregate them with the
/// very code that aggregates live measurements, so wiring up the real streams
/// changes where the data comes from and nothing about how it is read.
abstract final class DemoChartData {
  /// Cumulative step readings across this week, as a pedometer reports them:
  /// a running total that only ever grows.
  static List<Measurement> get stepMeasurements {
    const stepsPerDay = [5300, 10400, 5600, 400, 14200, 9800, 12300];
    var total = 0;

    return [
      for (final (index, steps) in stepsPerDay.indexed) ...[
        // One reading at the start of the day and one at the end, so the
        // difference between them is that day's steps.
        _measurement(StepCount(steps: total), _startOfWeek.add(Duration(days: index, hours: 6))),
        _measurement(StepCount(steps: total += steps), _startOfWeek.add(Duration(days: index, hours: 22))),
      ],
    ];
  }

  /// A day of heart rate as a Polar strap reports it - one reading per minute,
  /// quiet at night and higher around midday.
  static List<Measurement> get heartRateMeasurements => [
    for (final (dayOffset, dayScale) in _dailyIntensity.indexed)
      for (final (hour, (low, high)) in _hourlyBands.indexed)
        for (final minute in const [10, 30, 50])
          _measurement(
            PolarHR(samples: [PolarHRSample(hr: _hrAt(low, high, dayScale, minute), rrsMs: const [], contactStatus: true, contactStatusSupported: true)]),
            _startOfWeek.add(Duration(days: dayOffset, hours: hour, minutes: minute)),
          ),
  ];

  /// Activity transitions across this week. The recognition probe reports the
  /// activity it sees; a duration is the gap until the next, different one.
  static List<Measurement> get activityMeasurements => [
    for (final (dayOffset, day) in _dailyActivities.indexed)
      for (final (type, startHour, endHour) in day) ...[
        _measurement(Activity(type: type, confidence: 100), _startOfWeek.add(Duration(days: dayOffset, hours: startHour))),
        _measurement(
          Activity(type: ActivityType.STILL, confidence: 100),
          _startOfWeek.add(Duration(days: dayOffset, hours: endHour)),
        ),
      ],
  ];

  static Measurement _measurement(Data data, DateTime at) =>
      Measurement(sensorStartTime: at.microsecondsSinceEpoch, data: data);

  /// Monday of the current week, at midnight.
  static DateTime get _startOfWeek {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - 1));
  }

  /// A heart rate inside [low]-[high], nudged by the day's intensity and
  /// varied by the minute so the band is not a flat line.
  static int _hrAt(double low, double high, double dayScale, int minute) =>
      (low + (high - low) * ((minute % 30) / 30) * dayScale).round();

  /// How hard each weekday was, Monday first - scales that day's bands.
  static const List<double> _dailyIntensity = [0.8, 1.0, 0.7, 0.5, 1.0, 0.9, 0.75];

  /// The resting-to-peak band for each hour of the day.
  static const List<(double, double)> _hourlyBands = [
    (48, 58), (46, 55), (45, 54), (45, 53), (46, 56), (50, 62),
    (55, 72), (62, 88), (66, 95), (64, 92), (68, 99), (70, 101),
    (66, 94), (63, 88), (61, 84), (65, 91), (69, 97), (72, 104),
    (68, 96), (63, 86), (58, 78), (54, 70), (51, 64), (49, 60),
  ];

  /// (activity, start hour, end hour) per weekday, Monday first.
  static const List<List<(ActivityType, int, int)>> _dailyActivities = [
    [(ActivityType.WALKING, 8, 9), (ActivityType.ON_BICYCLE, 17, 18)],
    [(ActivityType.WALKING, 7, 8), (ActivityType.RUNNING, 18, 19), (ActivityType.ON_BICYCLE, 12, 13)],
    [(ActivityType.WALKING, 8, 9), (ActivityType.ON_BICYCLE, 16, 17)],
    [(ActivityType.WALKING, 12, 13)],
    [(ActivityType.WALKING, 7, 8), (ActivityType.RUNNING, 17, 18), (ActivityType.ON_BICYCLE, 19, 20)],
    [(ActivityType.WALKING, 10, 11), (ActivityType.ON_BICYCLE, 14, 15)],
    [(ActivityType.WALKING, 9, 10), (ActivityType.RUNNING, 11, 12), (ActivityType.ON_BICYCLE, 15, 16)],
  ];
}
