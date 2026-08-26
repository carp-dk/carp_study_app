part of carp_study_app;

class SleepCardViewModel extends SerializableViewModel<WeeklySleep> {
  @override
  WeeklySleep createModel() => WeeklySleep();

  /// The role name this card's data streams are keyed by - health data is
  /// produced by the Health Service, not the phone. Null if the deployment
  /// isn't loaded yet or doesn't include it.
  String? get deviceRoleName => roleOf(HealthService.DEVICE_TYPE);

  /// Whether any sleep at all was recorded in the last 7 nights - a card of
  /// seven empty bars says nothing, so the page hides it.
  bool get hasData => nights.any((night) => night.minutes > 0);

  /// Sleep for the 7 nights ending today, oldest first - today is always the
  /// last (rightmost) entry, as on the Steps and Activity cards.
  List<DailySleep> get nights => model.last7Days();

  /// The real sleep stages, deepest first - the order they stack in the
  /// chart. Disjoint spans of actual sleep, so they can be summed. A watch
  /// (Apple Health) or a stage-writing app (Health Connect) reports these.
  static const List<String> sleepStageTypes = ['SLEEP_DEEP', 'SLEEP_LIGHT', 'SLEEP_REM'];

  /// Sleep with no stage breakdown, most precise first. An iPhone with no
  /// watch reports ASLEEP; Health Connect reports a SESSION for an app that
  /// writes one without stages. Both span the same night as the stages
  /// would, so they are fallbacks rather than something to add on top.
  static const List<String> unstagedTypes = ['SLEEP_ASLEEP', sleepSessionType];

  /// A whole sleep session, bedtime to wake-up.
  static const String sleepSessionType = 'SLEEP_SESSION';

  /// Every health data type this card needs. The health probe silently drops
  /// the ones the current platform does not support, so a protocol can ask
  /// for all of them and get whatever the phone actually has.
  static const Set<String> sleepDataTypes = {...sleepStageTypes, ...unstagedTypes};

  /// Stream of health measurements carrying sleep.
  Stream<Measurement>? get sleepEvents =>
      controller?.measurements.where((measurement) => _minutesOf(measurement.data) != null);

  /// The minutes of sleep in [data], or null if it is not a sleep reading.
  ///
  /// Both platforms report a duration-typed reading with its value already
  /// converted to minutes by the health plugin.
  static double? _minutesOf(Data data) {
    if (data is! HealthData || !sleepDataTypes.contains(data.healthDataType)) return null;
    final value = data.value;
    return value is NumericHealthValue ? value.numericValue.toDouble() : null;
  }

  /// The morning [data] is charted on - the one the user woke up in.
  ///
  /// A night is not a calendar day: going to bed at 23:10 and waking at 06:00
  /// spans two, and its stages land on either side of midnight. Splitting the
  /// day at noon instead keeps them together - a reading ending in the
  /// morning belongs to that morning, one ending in the evening belongs to
  /// the next.
  ///
  /// ponytail: noon boundary, so a shift worker sleeping across midday is
  /// split in two. Grouping readings into sessions by gap would fix it.
  static DateTime _nightOf(HealthData data) {
    final end = data.dateTo.toLocal();
    return end.hour < 12 ? end : end.add(const Duration(days: 1));
  }

  DateTime get _startOfWindow => DateTime.now().subtract(const Duration(days: 6));

  String get startOfWeek => DateFormat('dd').format(_startOfWindow);

  String get endOfWeek => DateFormat('dd').format(DateTime.now());

  String get currentMonth => DateFormat('MMM').format(_startOfWindow);

  String get nextMonth => DateFormat('MMM').format(DateTime.now());

  String get currentYear => DateFormat('yyyy').format(DateTime.now());

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    sleepEvents?.listen((measurement) {
      final data = measurement.data as HealthData;
      // Traces where sleep comes from: the health probe reads the past 30
      // days from Health Connect / Apple Health - an OS store that survives
      // app uninstall, so old (incl. once mock-written) nights reappear.
      debug('$runtimeType - sleep from health probe: ${data.healthDataType}, ${data.dateFrom} - ${data.dateTo}');
      _record(model, measurement);
      notifyListeners();
    }, onError: onMeasurementStreamError);
  }

  /// Fold [measurement] into [into], if it carries sleep.
  static void _record(WeeklySleep into, Measurement measurement) {
    final data = measurement.data;
    final minutes = _minutesOf(data);
    if (minutes == null) return;
    into.addSleep(_nightOf(data as HealthData), minutes, type: data.healthDataType);
  }

  /// Recompute the trailing 7 nights from backfilled [measurements],
  /// replacing whatever this call previously computed - safe to call again on
  /// every refresh without double-counting.
  void addMeasurements(List<Measurement> measurements) {
    debug('$runtimeType - backfilled ${measurements.length} sleep measurements from CAWS');
    model.clearSleep();
    for (final measurement in measurements) {
      _record(model, measurement);
    }
    notifyListeners();
  }
}

/// Sleep minutes organized by the night they belong to.
@JsonSerializable(includeIfNull: false)
class WeeklySleep extends DataModel {
  /// Minutes per night per health data type, keyed by [_dayKey]
  /// (e.g. "2026-08-21", the morning the user woke up) then by the type -
  /// a stage name, or [SleepCardViewModel.sleepSessionType].
  Map<String, Map<String, double>> nightlyMinutes = {};

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Add [minutes] of [type] to the night of [date]. A night arrives as many
  /// readings - several per stage, or one per session on a night with
  /// wake-ups - so readings of the same type accumulate.
  void addSleep(DateTime date, double minutes, {required String type}) {
    final night = nightlyMinutes.putIfAbsent(_dayKey(date), () => {});
    night[type] = (night[type] ?? 0) + minutes;
  }

  void clearSleep() => nightlyMinutes.clear();

  /// How the night of [date] stacks up, as minutes of each
  /// [SleepCardViewModel.sleepStageTypes] followed by one unstaged segment.
  ///
  /// The three sources overlap - a session contains its stages, and a phone
  /// can report generic ASLEEP alongside a watch's staged sleep - so only the
  /// most detailed one available is used, never a sum across them. That
  /// leaves either a staged night (last segment 0) or a single block.
  List<double> segmentsOn(DateTime date) {
    final night = nightlyMinutes[_dayKey(date)] ?? const <String, double>{};
    final stages = [for (final stage in SleepCardViewModel.sleepStageTypes) night[stage] ?? 0];
    if (stages.any((minutes) => minutes > 0)) return [...stages, 0];

    final unstaged = SleepCardViewModel.unstagedTypes.map((type) => night[type] ?? 0);
    return [...stages.map((_) => 0.0), unstaged.firstWhere((minutes) => minutes > 0, orElse: () => 0)];
  }

  /// Minutes asleep on the night of [date].
  double minutesOn(DateTime date) => segmentsOn(date).fold<double>(0, (sum, minutes) => sum + minutes);

  /// Sleep for the 7 nights ending on [today] (defaults to now), oldest
  /// first - zero for any night with nothing recorded. Today is always last.
  List<DailySleep> last7Days({DateTime? today}) {
    final end = today ?? DateTime.now();
    return List.generate(7, (i) {
      final date = end.subtract(Duration(days: 6 - i));
      return DailySleep(date, minutesOn(date));
    });
  }

  @override
  WeeklySleep fromJson(Map<String, dynamic> json) => _$WeeklySleepFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeeklySleepToJson(this);
}

/// Sleep for the night ending on the morning of [date].
class DailySleep {
  final DateTime date;

  /// Minutes asleep that night.
  final double minutes;

  DailySleep(this.date, this.minutes);

  /// Hours asleep that night, for display.
  double get hours => minutes / 60;
}
