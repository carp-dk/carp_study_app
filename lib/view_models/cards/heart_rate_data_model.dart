part of carp_study_app;

class HeartRateCardViewModel extends SerializableViewModel<HourlyHeartRate> {
  @override
  HourlyHeartRate createModel() => HourlyHeartRate();

  /// A map of heart rate values for each hour of the day.
  /// The key is the hour of the day (0-23) and the value is the min and max heart rate for that hour.
  Map<int, HeartRateMinMaxPrHour> get hourlyHeartRate => model.hourlyHeartRate;

  /// The min and max heart rate per weekday, Monday first.
  Map<int, HeartRateMinMaxPrHour> get dailyHeartRate => model.dailyHeartRate;

  /// The average heart rate across [bands], taking the middle of each measured
  /// band. Null when none of them hold a value.
  static double? averageOf(Iterable<HeartRateMinMaxPrHour> bands) {
    final midpoints = bands
        .where((band) => band.min != null && band.max != null)
        .map((band) => (band.min! + band.max!) / 2);
    if (midpoints.isEmpty) return null;
    return midpoints.reduce((a, b) => a + b) / midpoints.length;
  }

  /// The min and max across [bands], or nulls when none of them hold a value.
  static HeartRateMinMaxPrHour rangeOf(Iterable<HeartRateMinMaxPrHour> bands) {
    final measured = bands.where((band) => band.min != null && band.max != null);
    if (measured.isEmpty) return HeartRateMinMaxPrHour(null, null);
    return HeartRateMinMaxPrHour(
      measured.map((band) => band.min!).reduce(min),
      measured.map((band) => band.max!).reduce(max),
    );
  }

  /// The current heart rate
  double? get currentHeartRate => model.currentHeartRate;

  HeartRateMinMaxPrHour get dayMinMax => rangeOf(hourlyHeartRate.values);

  /// Fold [measurement] into [into], as a band for its weekday and - unless
  /// [hourly] is off - for its hour of the day.
  static void _record(HourlyHeartRate into, Measurement measurement, {bool hourly = true}) {
    final bpm = bpmOf(measurement);
    if (bpm == null || bpm <= 0) return;

    final at = measurement.dateTime;
    into.addHeartRate(bpm, weekday: at.weekday, hour: hourly ? at.hour : null);
    if (bpm > (into.maxHeartRate ?? 0)) into.maxHeartRate = bpm;
    if (bpm < (into.minHeartRate ?? double.infinity)) into.minHeartRate = bpm;
  }

  /// The beats per minute in [measurement], whichever sensor reported it.
  static double? bpmOf(Measurement measurement) => switch (measurement.data) {
    PolarHR data => data.samples.firstOrNull?.hr.toDouble(),
    MovesenseHR data => data.hr,
    _ => null,
  };

  final StreamGroup<Measurement> _group = StreamGroup.broadcast();

  /// Stream of heart rate readings in BPM, for the card to rebuild on.
  Stream<double>? get heartRateStream =>
      _group.stream.map(bpmOf).where((bpm) => bpm != null).cast<double>().asBroadcastStream();

  /// Stream of heart rate based on [PolarHR] measures.
  Stream<Measurement>? get polarHRStream =>
      controller?.measurements.where((measurement) => measurement.data is PolarHR);

  /// Stream of heart rate based on [MovesenseHR] measures.
  Stream<Measurement>? get movesenseHRStream =>
      controller?.measurements.where((measurement) => measurement.data is MovesenseHR);

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    if (polarHRStream != null) _group.add(polarHRStream!);
    if (movesenseHRStream != null) _group.add(movesenseHRStream!);

    _group.stream.listen((measurement) {
      final bpm = bpmOf(measurement);
      model.currentHeartRate = bpm != null && bpm > 0 ? bpm : null;
      _record(model, measurement);
      model.resetDataAtMidnight();
    }, onError: onMeasurementStreamError);
  }
}

@JsonSerializable(includeIfNull: false)
class HourlyHeartRate extends DataModel {
  /// A map of heart rate values for each hour of the day.
  ///
  ///    (hour of the day, min and max heart rate for that hour)
  ///
  /// The hour of the day is expressed as an integer between 0 and 23.
  /// The min and max heart rate is expressed as a [HeartRateMinMaxPrHour] object.
  Map<int, HeartRateMinMaxPrHour> hourlyHeartRate = {};

  /// The min and max heart rate per weekday, for the week view.
  ///
  /// Keyed by [DateTime.weekday], so Monday is 1.
  // ponytail: no weekly rollover - a study running past a week keeps widening
  // each day's band. Add one when studies actually run that long.
  Map<int, HeartRateMinMaxPrHour> dailyHeartRate = {};

  HourlyHeartRate() {
    for (int i = 0; i < 24; i++) {
      hourlyHeartRate[i] = HeartRateMinMaxPrHour(null, null);
    }
    for (int i = 1; i <= 7; i++) {
      dailyHeartRate[i] = HeartRateMinMaxPrHour(null, null);
    }
  }

  /// The last updated time of the heart rate.
  /// Used to reset the data at midnight.
  DateTime lastUpdated = DateTime.now();

  /// The current heart rate
  @JsonKey(includeFromJson: false, includeToJson: false)
  double? currentHeartRate;

  /// The minimum and maximum heart rate for the day
  /// Used to scale the graph
  double? maxHeartRate;
  double? minHeartRate;

  HourlyHeartRate resetDataAtMidnight() {
    if (lastUpdated.day != DateTime.now().day) {
      for (int i = 0; i < 24; i++) {
        hourlyHeartRate[i] = HeartRateMinMaxPrHour(null, null);
      }
      // The day bands survive - they are what the week view is made of.
      maxHeartRate = null;
      minHeartRate = null;
    }
    lastUpdated = DateTime.now();
    return this;
  }

  /// Widen the bands [heartRate] belongs to: its [weekday], and its [hour] of
  /// the day unless that is null.
  HourlyHeartRate addHeartRate(double heartRate, {required int weekday, int? hour}) {
    if (hour != null && (hour < 0 || hour > 23)) {
      throw AssertionError("hour must be in the range 0 to 23");
    }
    if (weekday < 1 || weekday > 7) {
      throw AssertionError("weekday must be in the range 1 to 7");
    }

    if (hour != null) hourlyHeartRate[hour] = _widen(hourlyHeartRate[hour], heartRate);
    dailyHeartRate[weekday] = _widen(dailyHeartRate[weekday], heartRate);
    return this;
  }

  /// [band] grown to include [heartRate], or a new band around it.
  static HeartRateMinMaxPrHour _widen(HeartRateMinMaxPrHour? band, double heartRate) {
    if (band?.min == null || band?.max == null) return HeartRateMinMaxPrHour(heartRate, heartRate);
    return band!
      ..min = min(band.min!, heartRate)
      ..max = max(band.max!, heartRate);
  }

  @override
  String toString() {
    String str = 'time | heart rate\n';
    hourlyHeartRate.forEach((time, heartRate) => str += '$time  | $heartRate\n');
    return str;
  }

  @override
  HourlyHeartRate fromJson(Map<String, dynamic> json) => _$HourlyHeartRateFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$HourlyHeartRateToJson(this);
}

@JsonSerializable(includeIfNull: false)
class HeartRateMinMaxPrHour {
  double? min;
  double? max;

  HeartRateMinMaxPrHour(this.min, this.max);

  @override
  String toString() => {'min': min, 'max': max}.toString();

  factory HeartRateMinMaxPrHour.fromJson(Map<String, dynamic> json) => _$HeartRateMinMaxPrHourFromJson(json);
  Map<String, dynamic> toJson() => _$HeartRateMinMaxPrHourToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateMinMaxPrHour && runtimeType == other.runtimeType && min == other.min && max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;
}
