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

      final viewModel = HeartRateCardViewModel(PolarSamplingPackage.HR, PolarDevice.DEVICE_TYPE);
      viewModel.init(controller);

      expect(viewModel.model, isA<HourlyHeartRate>());
      expect(viewModel.currentHeartRate, isNull);
      // No data yet: every hour bucket is present but empty.
      expect(viewModel.hourlyHeartRate.map((band) => band.value), everyElement(HeartRateMinMaxPrHour(null, null)));
    });
  });

  group('HourlyHeartRate', () {
    test('addHeartRate widens the band of both the hour slot and the calendar day', () {
      HourlyHeartRate hr = HourlyHeartRate();

      hr.addHeartRate(75, at: DateTime(2026, 8, 10, 12, 5));
      hr.addHeartRate(70, at: DateTime(2026, 8, 10, 12, 40));
      hr.addHeartRate(80, at: DateTime(2026, 8, 10, 12, 55));
      hr.addHeartRate(75, at: DateTime(2026, 8, 11, 13, 0));
      hr.addHeartRate(80, at: DateTime(2026, 8, 11, 13, 30));
      hr.addHeartRate(85, at: DateTime(2026, 8, 11, 13, 59));

      expect(hr.hourlyHeartRate['2026-08-10T12'], HeartRateMinMaxPrHour(70, 80));
      expect(hr.hourlyHeartRate['2026-08-11T13'], HeartRateMinMaxPrHour(75, 85));
      expect(hr.dailyHeartRate['2026-08-10'], HeartRateMinMaxPrHour(70, 80));
      expect(hr.dailyHeartRate['2026-08-11'], HeartRateMinMaxPrHour(75, 85));
    });

    test('last24Hours has an empty band for every hour with nothing recorded', () {
      HourlyHeartRate hr = HourlyHeartRate();
      hr.addHeartRate(75, at: DateTime(2026, 8, 11, 9, 0));

      final window = hr.last24Hours(now: DateTime(2026, 8, 11, 9, 30));

      expect(window.length, 24);
      expect(window.last.value, HeartRateMinMaxPrHour(75, 75));
      expect(window[22].value, HeartRateMinMaxPrHour(null, null));
    });

    test('last7Days has an empty band for every day with nothing recorded', () {
      HourlyHeartRate hr = HourlyHeartRate();
      hr.addHeartRate(75, at: DateTime(2026, 8, 11, 9, 0));

      final window = hr.last7Days(today: DateTime(2026, 8, 11));

      expect(window.length, 7);
      expect(window.last.value, HeartRateMinMaxPrHour(75, 75));
      expect(window.first.value, HeartRateMinMaxPrHour(null, null));
    });
  });
}
