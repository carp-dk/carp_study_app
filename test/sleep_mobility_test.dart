import 'dart:convert';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:carp_context_package/carp_context_package.dart';

import 'exports.dart';

Measurement _health(String type, num minutes, DateTime from) => Measurement.fromData(
  HealthData(
    uuid: '$type-$from',
    value: NumericHealthValue(numericValue: minutes),
    unit: 'MINUTE',
    healthDataType: type,
    dateFrom: from,
    dateTo: from.add(Duration(minutes: minutes.toInt())),
    platform: HealthPlatform.APPLE_HEALTH,
  ),
);

void main() {
  final bedtime = DateTime(2026, 8, 11, 23, 10);

  test('sleep survives a JSON round-trip from either platform into the card', () {
    // Register HealthData / NumericHealthValue in the FromJsonFactory, as
    // HealthSamplingPackage.onRegister() and the Health() ctor do in the app.
    FromJsonFactory().registerAll([
      NumericHealthValue(numericValue: 0),
      _health('SLEEP_SESSION', 1, bedtime).data as HealthData,
    ]);

    // How each platform serializes a night: Android reports whole-number
    // minutes (int) from a SLEEP_SESSION; iOS reports fractional minutes
    // (double) from SLEEP_ASLEEP. Backfill parses this JSON via
    // Measurement.fromJson, same as CAWS data-stream batches.
    for (final (type, platform, minutes) in [
      ('SLEEP_SESSION', 'GOOGLE_HEALTH_CONNECT', 480),
      ('SLEEP_ASLEEP', 'APPLE_HEALTH', 480.5),
    ]) {
      final json = jsonEncode(
        _health(type, 1, bedtime).toJson(),
      ).replaceFirst('"numericValue":1', '"numericValue":$minutes').replaceFirst('APPLE_HEALTH', platform);
      final model = SleepCardViewModel()
        ..addMeasurements([Measurement.fromJson(jsonDecode(json) as Map<String, dynamic>)]);

      expect(model.model.minutesOn(DateTime(2026, 8, 12)), minutes.toDouble(), reason: type);
    }
  });

  test('a staged night is summed and dated by wake-up, ignoring other health data', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      _health('SLEEP_DEEP', 90, bedtime),
      _health('SLEEP_LIGHT', 210, bedtime.add(const Duration(hours: 2))),
      _health('SLEEP_REM', 100, bedtime.add(const Duration(hours: 6))),
      _health('SLEEP_AWAKE', 25, bedtime.add(const Duration(hours: 3))), // awake is not sleep
      _health('STEPS', 4000, DateTime(2026, 8, 11, 12)),
    ]);

    // Stages are disjoint spans of real sleep, so they add up. Every one of
    // them ends on the 12th, so the whole night lands on the morning the
    // user woke up rather than being split across midnight.
    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 400);
    expect(model.model.minutesOn(DateTime(2026, 8, 11)), 0);

    // Segments come back in chart order (deep, light, REM, then unstaged)
    // so the stacked bar always draws them the same way round.
    expect(model.model.segmentsOn(DateTime(2026, 8, 12)), [90, 210, 100, 0]);
  });

  test('a night is not split at midnight', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      // Falling asleep before midnight: this stage both starts and ends on
      // the 11th, but it is part of the night that ends on the 12th.
      _health('SLEEP_LIGHT', 40, DateTime(2026, 8, 11, 22, 30)),
      _health('SLEEP_DEEP', 90, DateTime(2026, 8, 11, 23, 30)),
      _health('SLEEP_REM', 60, DateTime(2026, 8, 12, 5)),
    ]);

    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 190, reason: 'the whole night is on one bar');
    expect(model.model.minutesOn(DateTime(2026, 8, 11)), 0);
  });

  test('generic asleep is ignored when the watch also reported stages', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      // A watch stages the night while the phone writes its own flat
      // reading of the same sleep - adding both would double the night.
      _health('SLEEP_DEEP', 120, bedtime),
      _health('SLEEP_LIGHT', 300, bedtime.add(const Duration(hours: 2))),
      _health('SLEEP_ASLEEP', 430, bedtime),
      _health('SLEEP_SESSION', 480, bedtime),
    ]);

    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 420, reason: 'stages are the most detailed source');
    expect(model.model.segmentsOn(DateTime(2026, 8, 12)), [120, 300, 0, 0]);
  });

  test('an unstaged night draws as a single segment', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      _health('SLEEP_ASLEEP', 430, bedtime),
      _health('SLEEP_SESSION', 480, bedtime), // spans the awake time too
    ]);

    // ASLEEP is the time actually asleep, so it wins over the session that
    // merely brackets it - and only one of the two is ever counted.
    expect(model.model.segmentsOn(DateTime(2026, 8, 12)), [0, 0, 0, 430]);
  });

  test('the stack skips stages the phone did not record', () {
    // A phone reporting only a bare session: one segment, no gaps for the
    // three stages it knows nothing about.
    expect(stackSegments([0, 0, 0, 7.5], 0.08), [(3, 0.0, 7.5)]);
    // A staged night stacks deep -> light -> REM with a gap between each.
    expect(stackSegments([1.5, 3.5, 1.0, 0], 1), [(0, 0.0, 1.5), (1, 2.5, 6.0), (2, 7.0, 8.0)]);
  });

  test('stages win over the session that contains them', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      // Health Connect reports both: an 8 h session with 7 h of stages
      // inside it. Counting both would read as 15 h asleep.
      _health('SLEEP_SESSION', 480, bedtime),
      _health('SLEEP_DEEP', 120, bedtime),
      _health('SLEEP_LIGHT', 300, bedtime.add(const Duration(hours: 2))),
    ]);

    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 420, reason: 'the session is only a fallback');
  });

  test('sleep survives a save/restore round trip', () {
    final model = WeeklySleep()..addSleep(DateTime(2026, 8, 12, 6), 90, type: 'SLEEP_DEEP');
    final restored = model.fromJson(jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);

    expect(restored.minutesOn(DateTime(2026, 8, 12)), 90);
  });

  test('a night recorded as sessions only falls back to them, and accumulates wake-ups', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      _health('SLEEP_SESSION', 300, bedtime),
      _health('SLEEP_SESSION', 120, bedtime.add(const Duration(hours: 6))),
    ]);

    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 420);

    // Recomputing on refresh replaces rather than accumulates.
    model.addMeasurements([_health('SLEEP_SESSION', 300, bedtime)]);
    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 300);
  });

  test('mobility converts its units and keeps "no home found" distinct from 0%', () {
    final model = MobilityCardViewModel();
    model.addMeasurements([
      Measurement.fromData(
        Mobility(date: DateTime(2026, 8, 10), numberOfPlaces: 2, homeStay: 0.4, distanceTraveled: 5500),
      ),
      // Out overnight: the probe found no home, which must not read as 0%.
      Measurement.fromData(Mobility(date: DateTime(2026, 8, 11), numberOfPlaces: 3, distanceTraveled: 11300)),
    ]);

    final days = model.model.last7Days(today: DateTime(2026, 8, 11));
    expect(days.length, 7);

    final tenth = days[5];
    expect(tenth.homeStay, 40); // fraction -> percent
    expect(tenth.distance, 5.5); // meters -> kilometers
    expect(tenth.places, 2);

    expect(days.last.homeStay, isNull);
    expect(days.first.homeStay, isNull, reason: 'a day with no reading has no home stay either');
  });

  // The page hides every sensor card until the last 7 days hold any data -
  // these gates are what keeps an all-empty chart off screen.
  test('hasData gates open only when the last 7 days hold data', () {
    final sleep = SleepCardViewModel();
    final mobility = MobilityCardViewModel();
    final steps = StepsCardViewModel();
    final activity = ActivityCardViewModel();
    final heartRate = HeartRateCardViewModel(PolarSamplingPackage.HR, PolarDevice.DEVICE_TYPE);
    expect(sleep.hasData, isFalse);
    expect(mobility.hasData, isFalse);
    expect(mobility.hasDistanceData, isFalse);
    expect(steps.hasData, isFalse);
    expect(activity.hasData, isFalse);
    expect(heartRate.hasData, isFalse);

    sleep.model.addSleep(DateTime.now(), 420, type: 'SLEEP_SESSION');
    expect(sleep.hasData, isTrue);

    steps.model.increaseStepCount(DateTime.now(), 100);
    expect(steps.hasData, isTrue);

    // STILL is tracked but not charted, so it must not open the gate.
    activity.model.increaseActivityDuration(ActivityType.STILL, DateTime.now(), 30);
    expect(activity.hasData, isFalse);
    activity.model.increaseActivityDuration(ActivityType.WALKING, DateTime.now(), 30);
    expect(activity.hasData, isTrue);

    heartRate.model.addHeartRate(72, at: DateTime.now());
    expect(heartRate.hasData, isTrue);

    // First reading of the day: a place but no distance yet - the Mobility
    // card shows while the Distance card stays hidden.
    mobility.model.setMobilityFeatures(Mobility(date: DateTime.now(), numberOfPlaces: 1, distanceTraveled: 0));
    expect(mobility.hasData, isTrue);
    expect(mobility.hasDistanceData, isFalse);

    mobility.model.setMobilityFeatures(Mobility(date: DateTime.now(), numberOfPlaces: 2, distanceTraveled: 800));
    expect(mobility.hasDistanceData, isTrue);
  });
}
