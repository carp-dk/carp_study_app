import 'exports.dart';

@GenerateNiceMocks([
  MockSpec<SmartphoneDeploymentController>(),
  MockSpec<HeartRateCardViewModel>(),
  MockSpec<HourlyHeartRate>(),
  MockSpec<PolarHRSample>(),
  MockSpec<PolarHR>(),
  MockSpec<Measurement>(),
  MockSpec<DataModel>(),
])
void main() {
  setUp(() {});
  group("HeartRateCardViewModel", () {
    test('initializes HeartRateCardViewModel', skip: true, () {
      final controller = MockSmartphoneDeploymentController();
      final model = MockHeartRateCardViewModel();
      final dataModel = MockHourlyHeartRate();
      when(model.createModel()).thenReturn(dataModel);

      final viewModel = HeartRateCardViewModel();
      viewModel.init(controller);

      verify(model.createModel());
    });
    group('init', () {
      group('should listen to heart rate events', () {
        final mockSmartphoneDeploymentController = MockSmartphoneDeploymentController();
        final mockPolarHRSample = MockPolarHRSample();
        final mockPolarHRDatum = MockPolarHR();
        final mockMeasurement = MockMeasurement();
        final viewModel = HeartRateCardViewModel();
        final heartRateStreamController = StreamController<MockMeasurement>.broadcast();

        setUp(() {
          when(mockSmartphoneDeploymentController.measurements).thenAnswer((_) => heartRateStreamController.stream);

          viewModel.init(mockSmartphoneDeploymentController);
        });
        tearDownAll(() {
          heartRateStreamController.close();
        });
        group('and update model variables', () {
          test('with one event', () async {
            // Add a heart rate data point to the stream
            when(mockPolarHRSample.hr).thenReturn(80);
            when(mockPolarHRDatum.samples).thenReturn([mockPolarHRSample]);
            when(mockMeasurement.data).thenReturn(mockPolarHRDatum);

            heartRateStreamController.sink.add(mockMeasurement);

            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(viewModel.currentHeartRate, equals(80.0));
            expect(viewModel.dayMinMax, equals(HeartRateMinMaxPrHour(80, 80)));
            expect(viewModel.hourlyHeartRate,
                equals((HourlyHeartRate().addHeartRate(DateTime.now().hour, 80)).hourlyHeartRate));
          });
          test('with multiple events', () async {
            // Add a heart rate data point to the stream
            when(mockPolarHRSample.hr).thenReturn(90);
            when(mockPolarHRDatum.samples).thenReturn([mockPolarHRSample]);
            when(mockMeasurement.data).thenReturn(mockPolarHRDatum);

            heartRateStreamController.sink.add(mockMeasurement);

            await Future<void>.delayed(const Duration(milliseconds: 100));
            when(mockPolarHRSample.hr).thenReturn(60);
            when(mockPolarHRDatum.samples).thenReturn([mockPolarHRSample]);
            when(mockMeasurement.data).thenReturn(mockPolarHRDatum);

            heartRateStreamController.sink.add(mockMeasurement);

            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(viewModel.currentHeartRate, equals(60));
            expect(viewModel.dayMinMax, equals(HeartRateMinMaxPrHour(60, 90)));
            expect(
                viewModel.hourlyHeartRate,
                equals((HourlyHeartRate().addHeartRate(DateTime.now().hour, 60).addHeartRate(DateTime.now().hour, 90))
                    .hourlyHeartRate));
          });
          test('with events with data that is 0', () async {
            // Add a heart rate data point to the stream
            when(mockPolarHRSample.hr).thenReturn(0);
            when(mockPolarHRDatum.samples).thenReturn([mockPolarHRSample]);
            when(mockMeasurement.data).thenReturn(mockPolarHRDatum);

            heartRateStreamController.sink.add(mockMeasurement);

            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(viewModel.currentHeartRate, equals(null));
            expect(viewModel.dayMinMax, equals(HeartRateMinMaxPrHour(null, null)));
            expect(viewModel.hourlyHeartRate, equals((HourlyHeartRate()).hourlyHeartRate));
            // expect(viewModel.skinContact, equals(false));
          });
          test('with contactStatus being true', () async {
            // Add a heart rate data point to the stream
            when(mockPolarHRSample.hr).thenReturn(1);
            when(mockPolarHRSample.contactStatusSupported).thenReturn(true);
            when(mockPolarHRSample.contactStatus).thenReturn(true);
            when(mockPolarHRDatum.samples).thenReturn([mockPolarHRSample]);
            when(mockMeasurement.data).thenReturn(mockPolarHRDatum);

            heartRateStreamController.sink.add(mockMeasurement);

            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(viewModel.currentHeartRate, equals(anything));
            expect(viewModel.dayMinMax, equals(anything));
            expect(viewModel.hourlyHeartRate, equals(anything));
            // expect(viewModel.skinContact, equals(true));
          });
        });
      });
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

    test('addHeartRate', () {
      HourlyHeartRate hr = HourlyHeartRate();

      hr.addHeartRate(12, 75);
      hr.addHeartRate(12, 70);
      hr.addHeartRate(12, 80);
      hr.addHeartRate(13, 75);
      hr.addHeartRate(13, 80);
      hr.addHeartRate(13, 85);

      expect(hr.hourlyHeartRate[12], HeartRateMinMaxPrHour(70, 80));
      expect(hr.hourlyHeartRate[13], HeartRateMinMaxPrHour(75, 85));
    });

    test('addHeartRate with invalid input', () {
      HourlyHeartRate hr = HourlyHeartRate();

      expect(() => hr.addHeartRate(-1, 75), throwsA(isA<AssertionError>()));
      expect(() => hr.addHeartRate(24, 75), throwsA(isA<AssertionError>()));
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

class MockSerializableViewModel extends Mock implements SerializableViewModel {}

SerializableViewModel restore() {
  var viewModel = MockSerializableViewModel();
  when(viewModel.restore).thenReturn(() async => MockDataModel());

  return viewModel;
}
