part of carp_study_app;

class HeartRateCardViewModel extends SerializableViewModel<HourlyHeartRate> {
  @override
  HourlyHeartRate createModel() => HourlyHeartRate();

  /// A map of heart rate values for each hour of the day.
  /// The key is the hour of the day (0-23) and the value is the min and max heart rate for that hour.
  Map<int, HeartRateMinMaxPrHour> get hourlyHeartRate => model.hourlyHeartRate;

  /// The current heart rate
  double? get currentHeartRate => model.currentHeartRate;

  HeartRateMinMaxPrHour get dayMinMax => HeartRateMinMaxPrHour(model.minHeartRate, model.maxHeartRate);

  final StreamGroup<double> _group = StreamGroup.broadcast();

  Stream<double>? get heartRateStream => _group.stream.asBroadcastStream();

  /// Stream of heart rate based on [PolarHR] measures.
  Stream<double>? get polarHRStream => controller?.measurements
      .where((measurement) => measurement.data is PolarHR)
      .map((measurement) => (measurement.data as PolarHR).samples.firstOrNull?.hr.toDouble() ?? 0);

  /// Stream of heart rate based on [MovesenseHR] measures.
  Stream<double>? get movesenseHRStream => controller?.measurements
      .where((measurement) => measurement.data is MovesenseHR)
      .map((measurement) => (measurement.data as MovesenseHR).hr);

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    if (polarHRStream != null) _group.add(polarHRStream!);
    if (movesenseHRStream != null) _group.add(movesenseHRStream!);

    heartRateStream?.listen((hr) {
      if (!(hr > 0)) {
        model.currentHeartRate = null;
        return;
      }
      model.addHeartRate(DateTime.now().hour, hr);
      if (hr > (model.maxHeartRate ?? 0)) model.maxHeartRate = hr;
      if (hr < (model.minHeartRate ?? 100000)) model.minHeartRate = hr;
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

  HourlyHeartRate() {
    for (int i = 0; i < 24; i++) {
      hourlyHeartRate[i] = HeartRateMinMaxPrHour(null, null);
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
      maxHeartRate = null;
      minHeartRate = null;
    }
    lastUpdated = DateTime.now();
    return this;
  }

  /// Add a heart rate value for a given hour.
  /// If the hour already exists, the min and max values are updated.
  /// If the hour does not exist, it is added.
  HourlyHeartRate addHeartRate(int hour, double heartRate) {
    if (hour < 0 || hour > 23) {
      throw AssertionError("hour must be in the range 0 to 23");
    }

    currentHeartRate = heartRate;
    if (hourlyHeartRate.containsKey(hour)) {
      hourlyHeartRate.update(hour, (value) {
        double? minVal = value.min, maxVal = value.max;
        if (minVal != null && maxVal != null) {
          return value
            ..min = min(minVal, heartRate)
            ..max = max(maxVal, heartRate);
        } else {
          return value
            ..min = heartRate
            ..max = heartRate;
        }
      });
    } else {
      hourlyHeartRate[hour] = HeartRateMinMaxPrHour(heartRate, heartRate);
    }
    return this;
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
