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

    // Backfill parses CAWS data-stream batches via Measurement.fromJson.
    for (final type in ['SLEEP_SESSION', 'SLEEP_ASLEEP']) {
      final json = jsonEncode(_health(type, 480, bedtime).toJson());
      final model = SleepCardViewModel()
        ..addMeasurements([Measurement.fromJson(jsonDecode(json) as Map<String, dynamic>)]);

      expect(model.model.minutesOn(DateTime(2026, 8, 12)), 480, reason: type);
    }
  });

  test('a night counts from bedtime to wake-up, awake gaps included', () {
    // Real Samsung Health night, Wed 23 - Thu 24 Sep: a 7h 08m session whose
    // stages add up to only 4h 10m - the other 3h were 63 short wake-ups.
    final model = SleepCardViewModel();
    final bed = DateTime(2026, 9, 23, 22, 53);
    model.addMeasurements([
      _health('SLEEP_SESSION', 428, bed),
      _health('SLEEP_DEEP', 70, bed),
      _health('SLEEP_LIGHT', 127, bed.add(const Duration(minutes: 90))),
      _health('SLEEP_REM', 53, bed.add(const Duration(minutes: 300))),
      _health('STEPS', 4000, DateTime(2026, 9, 23, 12)),
    ]);

    final thursday = DateTime(2026, 9, 24);
    expect(model.model.minutesOn(thursday), 428);
    expect(model.model.segmentsOn(thursday), [70, 127, 53, 0, 178]);
    expect(model.model.minutesOn(DateTime(2026, 9, 23)), 0);
  });

  test('21:00 to 07:00 is 10 hours on the waking day, even with a wake-up at night', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      _health('SLEEP_SESSION', 170, DateTime(2026, 8, 11, 21)), // 21:00 - 23:50
      _health('SLEEP_SESSION', 410, DateTime(2026, 8, 12, 0, 10)), // 00:10 - 07:00
    ]);

    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 600);
    expect(model.model.minutesOn(DateTime(2026, 8, 11)), 0);
  });

  test('a morning sleep is not split at noon, and a nap counts on its own day', () {
    final model = SleepCardViewModel();
    model.addMeasurements([
      // Sat 29 Aug: 05:30 - 12:16, all on Saturday.
      _health('SLEEP_SESSION', 406, DateTime(2026, 8, 29, 5, 30)),
      // Thu 17 Sep: night to 06:19, then a 15:47 nap - both on Thursday.
      _health('SLEEP_SESSION', 472, DateTime(2026, 9, 16, 22, 27)),
      _health('SLEEP_SESSION', 68, DateTime(2026, 9, 17, 15, 47)),
    ]);

    expect(model.model.minutesOn(DateTime(2026, 8, 29)), 406);
    expect(model.model.minutesOn(DateTime(2026, 8, 30)), 0);
    expect(model.model.minutesOn(DateTime(2026, 9, 17)), 540);
  });

  test('an unstaged night is time asleep plus the awake rest of the session', () {
    final model = SleepCardViewModel();
    model.addMeasurements([_health('SLEEP_ASLEEP', 430, bedtime), _health('SLEEP_SESSION', 480, bedtime)]);

    expect(model.model.segmentsOn(DateTime(2026, 8, 12)), [0, 0, 0, 430, 50]);
  });

  test('the probe and backfill delivering the same reading count it once', () {
    final model = SleepCardViewModel();
    final night = _health('SLEEP_SESSION', 480, bedtime);
    model.addMeasurements([night, night]);
    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 480);

    // Recomputing on refresh replaces rather than accumulates.
    model.addMeasurements([_health('SLEEP_SESSION', 300, bedtime)]);
    expect(model.model.minutesOn(DateTime(2026, 8, 12)), 300);
  });

  test('the stack skips stages the phone did not record', () {
    // A phone reporting only a bare session: one segment, no gaps for the
    // three stages it knows nothing about.
    expect(stackSegments([0, 0, 0, 7.5], 0.08), [(3, 0.0, 7.5)]);
    // A staged night stacks deep -> light -> REM with a gap between each.
    expect(stackSegments([1.5, 3.5, 1.0, 0], 1), [(0, 0.0, 1.5), (1, 2.5, 6.0), (2, 7.0, 8.0)]);
  });

  test('sleep survives a save/restore round trip', () {
    final model = WeeklySleep()..addSleep(DateTime(2026, 8, 12, 6), 90, type: 'SLEEP_DEEP');
    final restored = model.fromJson(jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);

    expect(restored.minutesOn(DateTime(2026, 8, 12)), 90);
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
    final heartRate = HeartRateCardViewModel(PolarSamplingPackage.HR);
    expect(sleep.hasData, isFalse);
    expect(mobility.hasData, isFalse);
    expect(mobility.hasDistanceData, isFalse);
    expect(steps.hasData, isFalse);
    expect(activity.hasData, isFalse);
    expect(heartRate.hasData, isFalse);

    sleep.model.addSleep(DateTime.now(), 420, type: 'SLEEP_ASLEEP');
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
