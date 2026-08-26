part of carp_study_app;

/// One card per heart rate sensor this app supports, identified by its data
/// type namespace - the same string backfill fetches by, and what live
/// measurements are filtered on. Readings from different sensors are never
/// merged.
class HeartRateCardViewModel extends SerializableViewModel<HourlyHeartRate> {
  HeartRateCardViewModel(this.dataType, this.deviceType);

  /// The namespaced data type (e.g. [PolarSamplingPackage.HR]) this card
  /// sources from.
  final String dataType;

  /// The [DeviceConfiguration.type] of the hardware device this card sources
  /// from (e.g. [PolarDevice.DEVICE_TYPE]) - used to look up that device's
  /// role name in the deployment for backfill, since data streams are keyed
  /// by role name, not device type, and a study can rename the role.
  final String deviceType;

  /// The role name this card's data streams are keyed by (e.g.
  /// "Polar HR Sensor"), or null if the deployment isn't loaded yet or
  /// doesn't include this device type.
  String? get deviceRoleName => roleOf(deviceType);

  @override
  HourlyHeartRate createModel() => HourlyHeartRate();

  /// Whether any heart rate was recorded in the last 7 days - the page hides
  /// an all-empty chart.
  bool get hasData => dailyHeartRate.any((band) => band.value.min != null);

  /// Bands for the last 24 hours, oldest first - the current hour is always
  /// last, so the freshest reading is always on the right of the chart.
  List<HourBand> get hourlyHeartRate => model.last24Hours();

  /// Bands for the last 7 days, oldest first - today is always last.
  List<DayBand> get dailyHeartRate => model.last7Days();

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

  HeartRateMinMaxPrHour get dayMinMax => rangeOf(hourlyHeartRate.map((band) => band.value));

  /// Fold [measurement] into [into], widening the hour slot it falls in and
  /// the day it falls on.
  static void _record(HourlyHeartRate into, Measurement measurement) {
    final bpm = bpmOf(measurement);
    if (bpm == null || bpm <= 0) return;
    into.addHeartRate(bpm, at: measurement.dateTime);
    if (bpm > (into.maxHeartRate ?? 0)) into.maxHeartRate = bpm;
    if (bpm < (into.minHeartRate ?? double.infinity)) into.minHeartRate = bpm;
  }

  /// The beats per minute in [measurement], whichever sensor reported it.
  static double? bpmOf(Measurement measurement) => switch (measurement.data) {
    PolarHR data => data.samples.firstOrNull?.hr.toDouble(),
    MovesenseHR data => data.hr,
    _ => null,
  };

  /// Stream of measurements of this card's [dataType] only.
  Stream<Measurement>? get sourceStream =>
      controller?.measurements.where((measurement) => measurement.dataType.toString() == dataType);

  /// Stream of heart rate readings in BPM, for the card to rebuild on.
  Stream<double>? get heartRateStream =>
      sourceStream?.map(bpmOf).where((bpm) => bpm != null).cast<double>().asBroadcastStream();

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    sourceStream?.listen((measurement) {
      final bpm = bpmOf(measurement);
      model.currentHeartRate = bpm != null && bpm > 0 ? bpm : null;
      _record(model, measurement);
    }, onError: onMeasurementStreamError);
  }

  /// Recompute the trailing 24h/7d bands from backfilled [measurements],
  /// replacing whatever this call previously computed - safe to call again on
  /// every refresh without stale bands lingering. No ordering/carry
  /// requirement, [_record] widens bands independently.
  void addMeasurements(List<Measurement> measurements) {
    model.hourlyHeartRate.clear();
    model.dailyHeartRate.clear();
    model.maxHeartRate = null;
    model.minHeartRate = null;
    for (final measurement in measurements) {
      _record(model, measurement);
    }
    notifyListeners();
  }
}

/// A band of heart rate readings for one hour slot (an absolute hour, not a
/// clock hour), paired with the [hour] it starts at.
class HourBand {
  final DateTime hour;
  final HeartRateMinMaxPrHour value;
  HourBand(this.hour, this.value);
}

/// A band of heart rate readings for one calendar day, paired with its [date].
class DayBand {
  final DateTime date;
  final HeartRateMinMaxPrHour value;
  DayBand(this.date, this.value);
}

@JsonSerializable(includeIfNull: false)
class HourlyHeartRate extends DataModel {
  /// Heart rate bands per hour slot, keyed by [_hourKey] (e.g.
  /// "2026-08-21T14") - an absolute hour rather than a clock hour, so "now"
  /// is always the most recent key and readings never wrap around a day.
  Map<String, HeartRateMinMaxPrHour> hourlyHeartRate = {};

  /// Heart rate bands per calendar day, keyed by [_dayKey] (e.g.
  /// "2026-08-21") - an absolute date rather than a weekday, so a reading
  /// always lands on the day it was actually taken.
  Map<String, HeartRateMinMaxPrHour> dailyHeartRate = {};

  static String _hourKey(DateTime at) => DateFormat('yyyy-MM-ddTHH').format(at);
  static String _dayKey(DateTime at) => DateFormat('yyyy-MM-dd').format(at);

  /// The current heart rate
  @JsonKey(includeFromJson: false, includeToJson: false)
  double? currentHeartRate;

  /// The minimum and maximum heart rate for the day
  /// Used to scale the graph
  double? maxHeartRate;
  double? minHeartRate;

  /// Widen the bands [heartRate] belongs to: the hour slot and calendar day
  /// containing [at].
  void addHeartRate(double heartRate, {required DateTime at}) {
    hourlyHeartRate[_hourKey(at)] = _widen(hourlyHeartRate[_hourKey(at)], heartRate);
    dailyHeartRate[_dayKey(at)] = _widen(dailyHeartRate[_dayKey(at)], heartRate);
  }

  /// [band] grown to include [heartRate], or a new band around it.
  static HeartRateMinMaxPrHour _widen(HeartRateMinMaxPrHour? band, double heartRate) {
    if (band?.min == null || band?.max == null) return HeartRateMinMaxPrHour(heartRate, heartRate);
    return band!
      ..min = min(band.min!, heartRate)
      ..max = max(band.max!, heartRate);
  }

  /// Bands for the 24 hours ending on the current hour (defaults to now),
  /// oldest first - an empty band for any hour with nothing recorded. The
  /// current hour is always last, so the freshest data is always on the
  /// right of the chart.
  List<HourBand> last24Hours({DateTime? now}) {
    final end = now ?? DateTime.now();
    return List.generate(24, (i) {
      final hour = DateTime(end.year, end.month, end.day, end.hour).subtract(Duration(hours: 23 - i));
      return HourBand(hour, hourlyHeartRate[_hourKey(hour)] ?? HeartRateMinMaxPrHour(null, null));
    });
  }

  /// Bands for the 7 days ending on [today] (defaults to now), oldest first -
  /// an empty band for any day with nothing recorded. Today is always last.
  List<DayBand> last7Days({DateTime? today}) {
    final end = today ?? DateTime.now();
    return List.generate(7, (i) {
      final date = end.subtract(Duration(days: 6 - i));
      return DayBand(date, dailyHeartRate[_dayKey(date)] ?? HeartRateMinMaxPrHour(null, null));
    });
  }

  @override
  String toString() {
    String str = 'hour | heart rate\n';
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
