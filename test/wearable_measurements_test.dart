import 'dart:convert';

import 'exports.dart';

class _WatchManager extends AppleWatchDeviceManager {
  final batches = StreamController<AppleWatchRecords>();

  @override
  Stream<AppleWatchRecords> get records => batches.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();
  SamplingPackageRegistry().register(AppleWatchSamplingPackage());

  test('AWARE watch batches become serializable CARP measurements with watch timestamps', () async {
    final manager = _WatchManager();
    addTearDown(manager.batches.close);
    final probe = AppleWatchHeartRateProbe()..deviceManager = manager;
    final result = probe.stream.first;
    manager.batches.add(
      AppleWatchRecords(
        table: AppleWatchTable.heartRate,
        chunkIndex: 1,
        totalChunks: 1,
        records: [
          {'id': 1, 'deviceId': 'watch-123', 'timestamp': 1700000000000, 'hr': 72.0},
        ],
      ),
    );

    final measurement = await result;
    final data = measurement.data as AppleWatchHeartRate;
    expect(data.hr, 72);
    expect(data.deviceId, 'watch-123');
    expect(data.timestamp.millisecondsSinceEpoch, 1700000000000);
    final restored = Measurement.fromJson(jsonDecode(jsonEncode(measurement)) as Map<String, dynamic>);
    expect((restored.data as AppleWatchHeartRate).hr, 72);
  });
}
