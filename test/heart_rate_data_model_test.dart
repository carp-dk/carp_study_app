import 'exports.dart';

@GenerateNiceMocks([MockSpec<SmartphoneStudyController>()])
void main() {
  group("HeartRateCardViewModel", () {
    // These cover the real, measurement-backed behaviour - not the placeholder
    // data the charts fall back to while a study has collected nothing, which
    // a production deployment never shows.
    setUp(() => AppConfig.deploymentMode = DeploymentMode.production);
    tearDown(() => AppConfig.deploymentMode = DeploymentMode.local);

    test('initializes with an empty heart rate model', () {
      final controller = MockSmartphoneStudyController();
      when(controller.measurements).thenAnswer((_) => const Stream<Measurement>.empty());

      final viewModel = HeartRateCardViewModel();
      viewModel.init(controller);

      expect(viewModel.model, isA<HourlyHeartRate>());
      expect(viewModel.currentHeartRate, isNull);
      // No data yet: every hour bucket is present but empty.
      expect(viewModel.hourlyHeartRate.values, everyElement(HeartRateMinMaxPrHour(null, null)));
    });
  });

  group('HourlyHeartRate', () {
    test('resetDataAtMidnight', () {
      // create an HourlyHeartRate object with some data
      HourlyHeartRate hr = HourlyHeartRate();
      hr.hourlyHeartRate[12] = HeartRateMinMaxPrHour(70, 80);
      hr.hourlyHeartRate[13] = HeartRateMinMaxPrHour(75, 85);
      hr.maxHeartRate = 85;
      hr.minHeartRate = 70;
      hr.lastUpdated = DateTime.now().subtract(const Duration(days: 1)); // yesterday

      // call resetDataAtMidnight
      hr.resetDataAtMidnight();

      // verify that the data was reset
      expect(hr.hourlyHeartRate[12], HeartRateMinMaxPrHour(null, null));
      expect(hr.hourlyHeartRate[13], HeartRateMinMaxPrHour(null, null));
      expect(hr.maxHeartRate, null);
      expect(hr.minHeartRate, null);
      expect(hr.lastUpdated.day, DateTime.now().day);
    });

    test('addHeartRate widens the band of both the hour and the weekday', () {
      HourlyHeartRate hr = HourlyHeartRate();

      hr.addHeartRate(75, weekday: 1, hour: 12);
      hr.addHeartRate(70, weekday: 1, hour: 12);
      hr.addHeartRate(80, weekday: 1, hour: 12);
      hr.addHeartRate(75, weekday: 2, hour: 13);
      hr.addHeartRate(80, weekday: 2, hour: 13);
      hr.addHeartRate(85, weekday: 2, hour: 13);

      expect(hr.hourlyHeartRate[12], HeartRateMinMaxPrHour(70, 80));
      expect(hr.hourlyHeartRate[13], HeartRateMinMaxPrHour(75, 85));
      expect(hr.dailyHeartRate[1], HeartRateMinMaxPrHour(70, 80));
      expect(hr.dailyHeartRate[2], HeartRateMinMaxPrHour(75, 85));
    });

    test('addHeartRate without an hour only records the weekday', () {
      HourlyHeartRate hr = HourlyHeartRate();

      hr.addHeartRate(75, weekday: 3);

      expect(hr.dailyHeartRate[3], HeartRateMinMaxPrHour(75, 75));
      expect(hr.hourlyHeartRate.values, everyElement(HeartRateMinMaxPrHour(null, null)));
    });

    test('addHeartRate with invalid input', () {
      HourlyHeartRate hr = HourlyHeartRate();

      expect(() => hr.addHeartRate(75, weekday: 1, hour: -1), throwsA(isA<AssertionError>()));
      expect(() => hr.addHeartRate(75, weekday: 1, hour: 24), throwsA(isA<AssertionError>()));
      expect(() => hr.addHeartRate(75, weekday: 0), throwsA(isA<AssertionError>()));
      expect(() => hr.addHeartRate(75, weekday: 8), throwsA(isA<AssertionError>()));
    });

    test('resetDataAtMidnight at other times of day', () {
      HourlyHeartRate hr = HourlyHeartRate();
      hr.hourlyHeartRate[12] = HeartRateMinMaxPrHour(70, 80);
      hr.hourlyHeartRate[13] = HeartRateMinMaxPrHour(75, 85);
      hr.maxHeartRate = 85;
      hr.minHeartRate = 70;
      hr.lastUpdated = DateTime.now();

      hr.resetDataAtMidnight();

      expect(hr.hourlyHeartRate[12], HeartRateMinMaxPrHour(70, 80));
      expect(hr.hourlyHeartRate[13], HeartRateMinMaxPrHour(75, 85));
      expect(hr.maxHeartRate, 85);
      expect(hr.minHeartRate, 70);
      expect(hr.lastUpdated.day, DateTime.now().day);
    });
  });
}
