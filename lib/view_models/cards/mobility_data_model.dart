part of carp_study_app;

class MobilityCardViewModel extends SerializableViewModel<WeeklyMobility> {
  @override
  WeeklyMobility createModel() => WeeklyMobility();

  /// The role name this card's data streams are keyed by - mobility is
  /// produced by the Location Service, not the phone. Null if the deployment
  /// isn't loaded yet or doesn't include it.
  String? get deviceRoleName => roleOf(LocationService.DEVICE_TYPE);

  /// Mobility for the 7 days ending today, oldest first - today is always the
  /// last (rightmost) entry, as on the Steps and Activity cards.
  List<DailyMobility> get days => model.last7Days();

  /// Whether any mobility at all was recorded in the last 7 days - a card of
  /// seven empty bars says nothing, so the page hides it.
  bool get hasData => days.any((day) => day.places > 0 || day.homeStay != null || day.distance > 0);

  /// Whether any distance was travelled in the last 7 days. Separate from
  /// [hasData]: the first mobility reading of a day has distance 0 (distance
  /// only exists between two completed stops), so the Mobility card can have
  /// something to show while the Distance card does not.
  bool get hasDistanceData => days.any((day) => day.distance > 0);

  /// Stream of mobility [Measurement]s.
  Stream<Measurement>? get mobilityEvents =>
      controller?.measurements.where((measurement) => measurement.data is Mobility);

  DateTime get _startOfWindow => DateTime.now().subtract(const Duration(days: 6));

  String get startOfWeek => DateFormat('dd').format(_startOfWindow);

  String get endOfWeek => DateFormat('dd').format(DateTime.now());

  String get currentMonth => DateFormat('MMM').format(_startOfWindow);

  String get nextMonth => DateFormat('MMM').format(DateTime.now());

  String get currentYear => DateFormat('yyyy').format(DateTime.now());

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    // listen for mobility events and update the features
    mobilityEvents?.listen((measurement) {
      model.setMobilityFeatures(measurement.data as Mobility);
      notifyListeners();
    }, onError: onMeasurementStreamError);
  }

  /// Recompute the trailing 7 days from backfilled [measurements], replacing
  /// whatever this call previously computed - safe to call again on every
  /// refresh. The probe reports one already-aggregated set of features per
  /// day, so the latest reading for a day simply wins.
  void addMeasurements(List<Measurement> measurements) {
    model.dailyMobility.clear();
    final sorted = [...measurements]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    for (final measurement in sorted) {
      model.setMobilityFeatures(measurement.data as Mobility);
    }
    notifyListeners();
  }
}

/// Mobility features per calendar day, in terms of
///  * percentage at home (home stay)
///  * visited places
///  * distance traveled
@JsonSerializable(includeIfNull: false)
class WeeklyMobility extends DataModel {
  /// Mobility per calendar day, keyed by [_dayKey] (e.g. "2026-08-21") - an
  /// absolute date rather than a weekday, so a reading always lands on the
  /// day it was actually taken regardless of which day of the week is "now".
  Map<String, DailyMobility> dailyMobility = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Record the mobility features in [data] on the day they describe.
  void setMobilityFeatures(Mobility data) {
    final date = data.date ?? DateTime.now();

    dailyMobility[_dayKey(date)] = DailyMobility(
      date,
      data.numberOfPlaces ?? 0,
      // A fraction on the wire, a percentage on the chart. Stays null when
      // the probe could not work out a home - "no home found" is not the
      // same as "spent 0% of the time at home". Clamped because the fraction
      // is of the time observed so far, which can round past 1 on a partial
      // day, and the chart's axis stops at 100.
      data.homeStay == null ? null : (100 * data.homeStay!).round().clamp(0, 100),
      // Meters on the wire, kilometers on the chart.
      (data.distanceTraveled ?? 0) / 1000,
    );
  }

  /// Mobility for the 7 days ending on [today] (defaults to now), oldest
  /// first - an empty day for anything not recorded. Today is always last, so
  /// the freshest data is always on the right of the chart.
  List<DailyMobility> last7Days({DateTime? today}) {
    final end = today ?? DateTime.now();
    return List.generate(7, (i) {
      final date = end.subtract(Duration(days: 6 - i));
      return dailyMobility[_dayKey(date)] ?? DailyMobility(date, 0, null, 0);
    });
  }

  @override
  WeeklyMobility fromJson(Map<String, dynamic> json) => _$WeeklyMobilityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeeklyMobilityToJson(this);
}

/// Mobility features for one calendar [date].
@JsonSerializable(includeIfNull: false)
class DailyMobility {
  final DateTime date;
  final int places;

  /// Percentage of the time observed that day spent at home, [0..100], or
  /// null if the probe could not identify a home that day (see [MobilityCard]
  /// for how home is determined). Today's figure covers midnight until the
  /// last recorded stop, not a full 24 hours.
  final int? homeStay;

  /// Distance traveled that day, in kilometers.
  final double distance;

  DailyMobility(this.date, this.places, this.homeStay, this.distance);

  Map<String, dynamic> toJson() => _$DailyMobilityToJson(this);
  static DailyMobility fromJson(Map<String, dynamic> json) => _$DailyMobilityFromJson(json);
}
