part of carp_study_app;

class MobilityCardViewModel extends SerializableViewModel<WeeklyMobility> {
  @override
  WeeklyMobility createModel() => WeeklyMobility();

  /// Role mobility streams are keyed by - the Location Service, not the phone.
  String? get deviceRoleName => roleOf(LocationService.DEVICE_TYPE);

  /// Mobility for the 7 days ending today, oldest first.
  List<DailyMobility> get days => model.last7Days();

  /// Whether any mobility was recorded in the last 7 days - hides an empty card.
  bool get hasData => days.any((day) => day.places > 0 || day.homeStay != null || day.distance > 0);

  /// Whether any distance was travelled in the last 7 days - distance only
  /// exists between two completed stops, so it can lag [hasData].
  bool get hasDistanceData => days.any((day) => day.distance > 0);

  /// Stream of mobility [Measurement]s.
  Stream<Measurement>? get mobilityEvents =>
      controller?.measurements.where((measurement) => measurement.data is Mobility);


  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    // listen for mobility events and update the features
    mobilityEvents?.listen((measurement) {
      model.setMobilityFeatures(measurement.data as Mobility);
      notifyListeners();
    }, onError: onMeasurementStreamError);
  }

  /// Recompute the trailing 7 days from backfilled [measurements] -
  /// idempotent; the latest reading per day wins.
  void addMeasurements(List<Measurement> measurements) {
    model.dailyMobility.clear();
    final sorted = [...measurements]..sort((a, b) => a.sensorTime.compareTo(b.sensorTime));
    for (final measurement in sorted) {
      model.setMobilityFeatures(measurement.data as Mobility);
    }
    notifyListeners();
  }
}

/// Mobility features per calendar day: home stay, places, distance.
@JsonSerializable(includeIfNull: false)
class WeeklyMobility extends DataModel {
  /// Mobility per calendar day, keyed by [_dayKey] (e.g. "2026-08-21").
  Map<String, DailyMobility> dailyMobility = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Record the mobility features in [data] on the day they describe.
  void setMobilityFeatures(Mobility data) {
    final date = data.date ?? DateTime.now();

    dailyMobility[_dayKey(date)] = DailyMobility(
      date,
      data.numberOfPlaces ?? 0,
      // Fraction -> percentage; null means "no home found", not 0%.
      data.homeStay == null ? null : (100 * data.homeStay!).round().clamp(0, 100),
      // Meters on the wire, kilometers on the chart.
      (data.distanceTraveled ?? 0) / 1000,
    );
  }

  /// Mobility for the 7 days ending on [today] (defaults to now), oldest first.
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

  /// Percentage of observed time spent at home, [0..100], or null if no home
  /// could be identified that day.
  final int? homeStay;

  /// Distance traveled that day, in kilometers.
  final double distance;

  DailyMobility(this.date, this.places, this.homeStay, this.distance);

  Map<String, dynamic> toJson() => _$DailyMobilityToJson(this);
  static DailyMobility fromJson(Map<String, dynamic> json) => _$DailyMobilityFromJson(json);
}
