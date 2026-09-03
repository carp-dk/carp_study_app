import 'package:carp_context_package/carp_context_package.dart';

import 'exports.dart';

/// Self-check for the demo generator: a week of history lands on the cards,
/// and each live tick moves them forward rather than resetting them.
void main() {
  test('backfills a week and keeps growing on every tick', () async {
    AppConfig.demoMode = true;
    addTearDown(() => AppConfig.demoMode = false);

    final model = StatisticsViewModel(queryService: _NoQueryService());
    final demo = DemoDataService();
    // Cards subscribe on init, then get their history - as in the app, where
    // the bloc inits them and the statistics page refreshes them.
    model.polarHeartRateCardDataModel.init(_NoController());
    model.stepsCardDataModel.init(_NoController());
    demo.start(model);
    addTearDown(demo.stop);

    final heartRate = model.polarHeartRateCardDataModel;
    final steps = model.stepsCardDataModel;
    final activity = model.activityCardDataModel;
    final mobility = model.mobilityCardDataModel;
    final sleep = model.sleepCardDataModel;

    // Every card has a full week of data, so none of them are hidden.
    expect(heartRate.hasData, isTrue);
    expect(steps.hasData, isTrue);
    expect(activity.hasData, isTrue);
    expect(mobility.hasDistanceData, isTrue);
    expect(sleep.hasData, isTrue);

    // Yesterday is complete - today only up to now, so it is not compared.
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(steps.steps[5].steps, greaterThan(5000));
    expect(activity.minutesOn(ActivityType.RUNNING, yesterday), greaterThan(0));
    expect(heartRate.dailyHeartRate[5].value.max, greaterThan(100)); // the evening workout
    expect(sleep.nights[5].hours, inInclusiveRange(5, 10));

    // A tick adds to today rather than replacing it.
    final today = steps.steps.last.steps;
    demo.tick();
    await Future<void>.delayed(Duration.zero);

    expect(steps.steps.last.steps, greaterThan(today));
    expect(heartRate.currentHeartRate, greaterThan(0));
  });
}

/// A statistics view model with no CAWS behind it - demo mode never queries.
class _NoQueryService extends DataStreamQueryService {
  @override
  Future<List<Measurement>?> fetch(String dataType, {String? deviceRoleName}) async => null;
}

/// The cards only need a controller to subscribe; in demo mode the
/// measurements come from [DemoDataService], not from it.
class _NoController extends Fake implements SmartphoneStudyController {
  @override
  Stream<Measurement> get measurements => const Stream.empty();
  @override
  SmartphoneDeployment? get deployment => null;
}
