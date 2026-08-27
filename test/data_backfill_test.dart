import 'package:carp_context_package/carp_context_package.dart';

import 'exports.dart';

/// Self-check for the day-boundary reset in the Steps and Activity
/// `addMeasurements` - the only new aggregation logic added for backfill.
void main() {
  group('StepsCardViewModel.addMeasurements', () {
    test('resets the running baseline at each day boundary', () {
      final model = StepsCardViewModel();
      model.addMeasurements([
        Measurement.fromData(StepCount(steps: 100), _micros(DateTime(2026, 8, 10, 23, 0))), // Mon
        Measurement.fromData(StepCount(steps: 5), _micros(DateTime(2026, 8, 11, 0, 5))), // Tue, lower total
        Measurement.fromData(StepCount(steps: 55), _micros(DateTime(2026, 8, 11, 1, 0))), // Tue
      ]);

      expect(model.model.dailySteps['2026-08-10'], isNull); // single reading, no delta recorded
      expect(model.model.dailySteps['2026-08-11'], 50); // 55 - 5
    });

    test('a failed fetch leaves the card as it was, rather than emptying it', () async {
      final model = StatisticsViewModel(queryService: _FailingQueryService());
      final steps = model.stepsCardDataModel
        ..addMeasurements([
          Measurement.fromData(StepEvent(steps: 5), _micros(DateTime(2026, 8, 11, 0, 5))),
          Measurement.fromData(StepEvent(steps: 55), _micros(DateTime(2026, 8, 11, 1, 0))),
        ]);

      await model.refresh();

      expect(steps.model.dailySteps['2026-08-11'], 50);
    });

    test('folds StepEvent the same as the deprecated StepCount', () {
      final model = StepsCardViewModel();
      model.addMeasurements([
        Measurement.fromData(StepEvent(steps: 5), _micros(DateTime(2026, 8, 11, 0, 5))),
        Measurement.fromData(StepEvent(steps: 55), _micros(DateTime(2026, 8, 11, 1, 0))),
      ]);

      expect(model.model.dailySteps['2026-08-11'], 50);
    });

    test('is order-independent - measurements are sorted before folding', () {
      final model = StepsCardViewModel();
      model.addMeasurements([
        Measurement.fromData(StepCount(steps: 55), _micros(DateTime(2026, 8, 11, 1, 0))),
        Measurement.fromData(StepCount(steps: 5), _micros(DateTime(2026, 8, 11, 0, 5))),
      ]);

      expect(model.model.dailySteps['2026-08-11'], 50);
    });

    test('calling it again replaces the result instead of adding to it', () {
      final model = StepsCardViewModel();
      final measurements = [
        Measurement.fromData(StepCount(steps: 5), _micros(DateTime(2026, 8, 11, 0, 5))),
        Measurement.fromData(StepCount(steps: 55), _micros(DateTime(2026, 8, 11, 1, 0))),
      ];

      model.addMeasurements(measurements);
      model.addMeasurements(measurements); // a second refresh over the same window

      expect(model.model.dailySteps['2026-08-11'], 50); // not 100
    });

    test('ignores the climb back to a pre-reset total', () {
      // Readings from before and after a reboot are different counting
      // epochs. The drop is guarded, but the jump back up to the old series
      // used to be counted in full - one 196500-step "day".
      final model = StepsCardViewModel();
      model.addMeasurements([
        Measurement.fromData(StepCount(steps: 0), _micros(DateTime(2026, 8, 11, 8, 0))), // reboot
        Measurement.fromData(StepCount(steps: 500), _micros(DateTime(2026, 8, 11, 9, 0))),
        Measurement.fromData(StepCount(steps: 197000), _micros(DateTime(2026, 8, 11, 10, 0))), // stale epoch
      ]);

      expect(model.model.dailySteps['2026-08-11'], 500);
    });

    test('ignores a drop in the running total instead of counting it as negative steps', () {
      // A phone reboot/reinstall resets the pedometer's cumulative count to
      // ~0. Without a guard this reads as a huge negative delta.
      final model = StepsCardViewModel();
      model.addMeasurements([
        Measurement.fromData(StepCount(steps: 194151), _micros(DateTime(2026, 8, 11, 8, 0))),
        Measurement.fromData(StepCount(steps: 30), _micros(DateTime(2026, 8, 11, 9, 0))), // pedometer reset
        Measurement.fromData(StepCount(steps: 80), _micros(DateTime(2026, 8, 11, 10, 0))),
      ]);

      expect(model.model.dailySteps['2026-08-11'], 50); // only the post-reset growth (80 - 30)
      expect(model.model.dailySteps.values.every((steps) => steps >= 0), isTrue);
    });

    test('resyncs the live-stream baseline, so a later live tick does not re-add the backfilled delta', () async {
      // This is the 197k spike: without a resync, addMeasurements() computes
      // its own delta from a *local* previous reading, but leaves the live
      // stream's remembered baseline stale - so the next live tick diffs
      // against that stale value instead of the just-backfilled total.
      final controller = MockSmartphoneStudyController();
      final live = StreamController<Measurement>();
      when(controller.measurements).thenAnswer((_) => live.stream);

      final model = StepsCardViewModel();
      model.init(controller);

      // A live reading establishes an early baseline of 10 steps.
      live.add(Measurement.fromData(StepCount(steps: 10), _micros(DateTime(2026, 8, 11, 8, 0))));
      await Future<void>.delayed(Duration.zero);

      // Backfill later runs and recomputes the day from scratch, ending on 5010.
      model.addMeasurements([
        Measurement.fromData(StepCount(steps: 10), _micros(DateTime(2026, 8, 11, 8, 0))),
        Measurement.fromData(StepCount(steps: 5010), _micros(DateTime(2026, 8, 11, 18, 0))),
      ]);
      expect(model.model.dailySteps['2026-08-11'], 5000); // 5010 - 10

      // A live tick right after backfill should add only real new steps, not
      // re-diff against the stale 10-step baseline from before the refresh.
      live.add(Measurement.fromData(StepCount(steps: 5020), _micros(DateTime(2026, 8, 11, 18, 1))));
      await Future<void>.delayed(Duration.zero);

      expect(model.model.dailySteps['2026-08-11'], 5010); // +10, not +5010
      await live.close();
    });

    test('last7Days always puts today last, regardless of the calendar weekday', () {
      final model = StepsCardViewModel();
      model.addMeasurements([
        Measurement.fromData(StepCount(steps: 5), _micros(DateTime(2026, 8, 11, 0, 5))),
        Measurement.fromData(StepCount(steps: 55), _micros(DateTime(2026, 8, 11, 1, 0))),
      ]);

      final window = model.model.last7Days(today: DateTime(2026, 8, 11));
      expect(window.length, 7);
      expect(window.last.date.day, 11);
      expect(window.last.steps, 50);
      expect(window.first.date, DateTime(2026, 8, 5));
    });
  });

  group('ActivityCardViewModel.addMeasurements', () {
    test('does not carry a duration across a day boundary', () {
      final model = ActivityCardViewModel();
      model.addMeasurements([
        Measurement.fromData(
          Activity(type: ActivityType.WALKING, confidence: 100),
          _micros(DateTime(2026, 8, 10, 23, 50)),
        ),
        Measurement.fromData(
          Activity(type: ActivityType.STILL, confidence: 100),
          _micros(DateTime(2026, 8, 11, 0, 20)),
        ),
      ]);

      // The walking->still gap spans midnight; per-day reset means it is
      // dropped rather than attributed to either day.
      expect(model.minutesOn(ActivityType.WALKING, DateTime(2026, 8, 10)), 0);
      expect(model.minutesOn(ActivityType.WALKING, DateTime(2026, 8, 11)), 0);
    });

    test('records a duration within the same day', () {
      final model = ActivityCardViewModel();
      model.addMeasurements([
        Measurement.fromData(
          Activity(type: ActivityType.WALKING, confidence: 100),
          _micros(DateTime(2026, 8, 11, 8, 0)),
        ),
        Measurement.fromData(
          Activity(type: ActivityType.STILL, confidence: 100),
          _micros(DateTime(2026, 8, 11, 8, 15)),
        ),
      ]);

      expect(model.minutesOn(ActivityType.WALKING, DateTime(2026, 8, 11)), 15);
    });

    test('calling it again replaces the result instead of adding to it', () {
      final model = ActivityCardViewModel();
      final measurements = [
        Measurement.fromData(
          Activity(type: ActivityType.WALKING, confidence: 100),
          _micros(DateTime(2026, 8, 11, 8, 0)),
        ),
        Measurement.fromData(
          Activity(type: ActivityType.STILL, confidence: 100),
          _micros(DateTime(2026, 8, 11, 8, 15)),
        ),
      ];

      model.addMeasurements(measurements);
      model.addMeasurements(measurements);

      expect(model.minutesOn(ActivityType.WALKING, DateTime(2026, 8, 11)), 15); // not 30
    });
  });

  group('HeartRateCardViewModel.addMeasurements', () {
    test('calling it again replaces the bands instead of only ever widening them', () {
      final model = HeartRateCardViewModel(PolarSamplingPackage.HR, PolarDevice.DEVICE_TYPE);

      model.addMeasurements([_polarHr(90, DateTime(2026, 8, 11, 8, 0))]);
      model.addMeasurements([_polarHr(70, DateTime(2026, 8, 11, 9, 0))]);

      // A later refresh that no longer includes the 90 bpm reading should not
      // leave it stuck as the max - the whole window is recomputed each time.
      expect(model.model.hourlyHeartRate['2026-08-11T08'], isNull);
      expect(model.model.hourlyHeartRate['2026-08-11T09'], HeartRateMinMaxPrHour(70, 70));
    });

    test('last24Hours always puts the current hour last, with every slot present', () {
      final model = HeartRateCardViewModel(PolarSamplingPackage.HR, PolarDevice.DEVICE_TYPE);
      model.addMeasurements([_polarHr(70, DateTime(2026, 8, 11, 9, 0))]);

      final window = model.model.last24Hours(now: DateTime(2026, 8, 11, 9, 30));
      expect(window.length, 24);
      expect(window.last.hour, DateTime(2026, 8, 11, 9));
      expect(window.last.value, HeartRateMinMaxPrHour(70, 70));
      expect(window.first.hour, DateTime(2026, 8, 10, 10));
    });
  });

  group('HeartRateCardViewModel.deviceRoleName', () {
    test('resolves the sensor device role, not the phone role, from the deployment', () {
      final deployment = SmartphoneDeployment(
        deviceConfiguration: Smartphone(roleName: Smartphone.DEFAULT_ROLE_NAME),
        registration: SmartphoneRegistration(deviceId: 'phone'),
        connectedDevices: {PolarDevice(roleName: 'Custom Polar Role')},
      );
      final controller = MockSmartphoneStudyController();
      when(controller.deployment).thenReturn(deployment);

      final model = HeartRateCardViewModel(PolarSamplingPackage.HR, PolarDevice.DEVICE_TYPE)..init(controller);

      // This is the bug that made backfill silently return nothing: querying
      // by the phone's role name instead of the sensor's finds no data stream.
      expect(model.deviceRoleName, 'Custom Polar Role');
      expect(model.deviceRoleName, isNot(Smartphone.DEFAULT_ROLE_NAME));
    });

    test('is null when the deployment does not include this device type', () {
      final deployment = SmartphoneDeployment(
        deviceConfiguration: Smartphone(roleName: Smartphone.DEFAULT_ROLE_NAME),
        registration: SmartphoneRegistration(deviceId: 'phone'),
      );
      final controller = MockSmartphoneStudyController();
      when(controller.deployment).thenReturn(deployment);

      final model = HeartRateCardViewModel(PolarSamplingPackage.HR, PolarDevice.DEVICE_TYPE)..init(controller);

      expect(model.deviceRoleName, isNull);
    });
  });

  group('card deviceRoleName', () {
    // Mobility and health stream under their connected service's role, not
    // the phone's - querying the phone's role for them is a CAWS 400.
    test('resolves a connected service role and is null for an absent one', () {
      final deployment = SmartphoneDeployment(
        deviceConfiguration: Smartphone(roleName: Smartphone.DEFAULT_ROLE_NAME),
        registration: SmartphoneRegistration(deviceId: 'phone'),
        connectedDevices: {LocationService()},
      );
      final controller = MockSmartphoneStudyController();
      when(controller.deployment).thenReturn(deployment);

      final mobility = MobilityCardViewModel()..init(controller);
      final sleep = SleepCardViewModel()..init(controller);

      expect(mobility.deviceRoleName, LocationService.DEFAULT_ROLE_NAME);
      expect(sleep.deviceRoleName, isNull);
    });
  });
}

/// A query service that always fails, as when the phone is offline.
class _FailingQueryService extends DataStreamQueryService {
  @override
  Future<List<Measurement>?> fetch(String dataType, {String? deviceRoleName}) async => null;
}

Measurement _polarHr(int bpm, DateTime at) => Measurement.fromData(
  PolarHR(
    samples: [PolarHRSample(hr: bpm, rrsMs: const [], contactStatus: true, contactStatusSupported: true)],
  ),
  _micros(at),
);

int _micros(DateTime dateTime) => dateTime.microsecondsSinceEpoch;
