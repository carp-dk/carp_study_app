part of carp_study_app;

class MobilityCardViewModel extends SerializableViewModel<WeeklyMobility> {
  @override
  WeeklyMobility createModel() => WeeklyMobility();

  Map<int, DailyMobility> get weekData => model.weekMobility;

  /// Stream of mobility [DataPoint] measures.
  Stream<Measurement>? get mobilityEvents =>
      controller?.measurements.where((measurement) => measurement.data is Mobility);

  final DateTime _startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  final DateTime _endOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(Duration(days: 6));

  String get startOfWeek => DateFormat('dd').format(_startOfWeek);

  String get endOfWeek => DateFormat('dd').format(_endOfWeek);

  String get currentMonth => DateFormat('MMM').format(DateTime(_startOfWeek.year, _startOfWeek.month));

  String get nextMonth => DateFormat('MMM').format(DateTime(_startOfWeek.year, _startOfWeek.month + 1, 1));

  String get currentYear => DateFormat('yyyy').format(DateTime(DateTime.now().year));

  MobilityCardViewModel();
  @override
  void init(SmartphoneDeploymentController ctrl) {
    super.init(ctrl);

    // listen for mobility events and update the features
    mobilityEvents?.listen((measurement) {
      Mobility mobility = measurement.data as Mobility;
      model.setMobilityFeatures(mobility);
    });
  }
}

/// Weekly mobility data in terms of
///  * percentage at home (home stay)
///  * visited places
///  * distance traveled
///
/// All organized pr week day. In accordance with Dart [DateTime] a week
/// starts with Monday, which has the value 1.
@JsonSerializable(includeIfNull: false)
class WeeklyMobility extends DataModel {
  /// A map of weekly data organized by the day of the week.
  Map<int, DailyMobility> weekMobility = {};

  WeeklyMobility() {
    for (int i = 1; i <= 7; i++) {
      weekMobility[i] = DailyMobility(i, 0, 0, 0);
    }
  }

  /// Update the mobility feature with [data].
  void setMobilityFeatures(Mobility data) {
    DateTime day = data.date ?? DateTime.now();

    weekMobility[day.weekday] = DailyMobility(day.weekday, data.numberOfPlaces ?? 0,
        data.homeStay != null && data.homeStay! > 0 ? (100 * (data.homeStay!)).toInt() : 0, data.distanceTraveled ?? 0);
  }

  @override
  WeeklyMobility fromJson(Map<String, dynamic> json) => _$WeeklyMobilityFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeeklyMobilityToJson(this);
}

/// Mobility features for a weekday.
@JsonSerializable(includeIfNull: false)
class DailyMobility extends DailyMeasure {
  final int places;
  final int homeStay;
  final double distance;

  DailyMobility(super.weekday, this.places, this.homeStay, this.distance);

  Map<String, dynamic> toJson() => _$DailyMobilityToJson(this);
  static DailyMobility fromJson(Map<String, dynamic> json) => _$DailyMobilityFromJson(json);
}
