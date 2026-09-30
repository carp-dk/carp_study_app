// Seeds Apple Health on a real iPhone with the last week of sleep and heart
// data, so any study's health probe collects it like data from a watch.
//
//   flutter test integration_test/seed_apple_health_test.dart -d <iPhone id>
//
// Tap "Turn On All" > Allow on the Health sheet. Re-running replaces what the
// previous run wrote; undo in Health > Sources > CARP Studies > Delete All Data.
import 'dart:math';

import 'package:carp_health_package/health_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

typedef Sample = ({HealthDataType type, double value, DateTime from, DateTime to});

const sleepTypes = [
  HealthDataType.SLEEP_IN_BED,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
];
const heartTypes = [
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
];

/// The [days] before [now]: nightly sleep in ~90 min cycles (deep early, REM
/// late, brief wakes) and heart rate about every minute, lower asleep, with
/// the odd workout.
List<Sample> generateWeek(DateTime now, {int days = 7, Random? random}) {
  random ??= Random();
  int between(int low, int high) => low + random!.nextInt(high - low + 1);
  double around(double mean, double spread) => mean + spread * (random!.nextDouble() + random.nextDouble() - 1);

  final start = now.subtract(Duration(days: days));
  final samples = <Sample>[];
  final nights = <(DateTime, DateTime)>[];
  void add(HealthDataType type, DateTime from, DateTime to, [double value = 0]) =>
      samples.add((type: type, value: value, from: from, to: to));

  for (
    var day = DateTime(start.year, start.month, start.day - 1, 23);
    day.isBefore(now);
    day = DateTime(day.year, day.month, day.day + 1, 23)
  ) {
    final bed = day.add(Duration(minutes: between(-45, 60)));
    final wake = bed.add(Duration(minutes: between(390, 510)));
    if (bed.isBefore(start) || wake.isAfter(now)) continue;
    nights.add((bed, wake));

    add(HealthDataType.SLEEP_IN_BED, bed, wake);
    var t = bed.add(Duration(minutes: between(5, 20)));
    add(HealthDataType.SLEEP_AWAKE, bed, t);
    for (var cycle = 0; t.isBefore(wake); cycle++) {
      final late = min(cycle / 5, 1.0);
      final plan = [
        (HealthDataType.SLEEP_LIGHT, between(15, 30)),
        (HealthDataType.SLEEP_DEEP, max(5, (between(20, 40) * (1 - late)).round())),
        (HealthDataType.SLEEP_LIGHT, between(10, 25)),
        (HealthDataType.SLEEP_REM, (between(8, 15) + 25 * late).round()),
        if (random.nextDouble() < 0.4) (HealthDataType.SLEEP_AWAKE, between(1, 5)),
      ];
      for (final (type, minutes) in plan) {
        var end = t.add(Duration(minutes: minutes, seconds: random.nextInt(60)));
        if (end.isAfter(wake)) end = wake;
        if (end.isAfter(t)) add(type, t, end);
        t = end;
      }
    }

    add(HealthDataType.RESTING_HEART_RATE, wake, wake, between(52, 60).toDouble());
    for (var i = between(3, 6); i > 0; i--) {
      final at = bed.add(wake.difference(bed) * random.nextDouble());
      add(HealthDataType.HEART_RATE_VARIABILITY_SDNN, at, at, around(60, 25));
    }
  }

  bool asleep(DateTime t) => nights.any((night) => !t.isBefore(night.$1) && t.isBefore(night.$2));
  var workoutUntil = start;
  for (var t = start; t.isBefore(now); t = t.add(Duration(seconds: between(50, 70)))) {
    if (!asleep(t) && !t.isBefore(workoutUntil) && random.nextDouble() < 0.0008) {
      workoutUntil = t.add(Duration(minutes: between(20, 60)));
    }
    final bpm = asleep(t) ? around(56, 5) : (t.isBefore(workoutUntil) ? around(135, 20) : around(74, 12));
    add(HealthDataType.HEART_RATE, t, t, bpm.roundToDouble());
  }
  return samples;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seed Apple Health with a week of sleep and heart data', (_) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final samples = generateWeek(now);

    expect(samples.length, greaterThanOrEqualTo(10000));
    expect(samples.every((s) => !s.from.isAfter(s.to) && !s.from.isBefore(start) && !s.to.isAfter(now)), isTrue);
    for (final type in [...sleepTypes, ...heartTypes]) {
      expect(samples.any((s) => s.type == type), isTrue, reason: '$type');
    }

    final health = Health();
    await health.configure();
    const types = [...sleepTypes, ...heartTypes];
    final granted = await health.requestAuthorization(
      types,
      permissions: [for (final _ in types) HealthDataAccess.READ_WRITE],
    );
    expect(granted, isTrue);

    // HealthKit only deletes this app's own samples - real watch data is safe.
    for (final type in types) {
      await health.delete(type: type, startTime: DateTime(2000), endTime: now);
    }

    for (var i = 0; i < samples.length; i += 100) {
      final written = await Future.wait(
        samples
            .skip(i)
            .take(100)
            .map((s) => health.writeHealthData(value: s.value, type: s.type, startTime: s.from, endTime: s.to)),
      );
      expect(written, everyElement(isTrue));
    }

    final stored = await health.getHealthDataFromTypes(types: types, startTime: start, endTime: now);
    expect(stored.length, greaterThanOrEqualTo(samples.length));
    debugPrint('Wrote ${samples.length} samples to Apple Health, ${stored.length} now in the last 7 days.');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
