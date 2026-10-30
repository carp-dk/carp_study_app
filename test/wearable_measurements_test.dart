import 'dart:convert';
import 'dart:io';

import 'package:carp_movesense_package/carp_movesense_package.dart';
import 'package:movesense_plus/movesense_plus.dart' as movesense;
import 'package:movesense_plus/movesense_plus_platform_interface.dart';

import 'exports.dart';

class _MovesensePlatform extends MovesensePlatform {
  String? requestedUri;

  @override
  Future<movesense.MdsResponse> request(movesense.MdsRequestMethod method, String uri, String contract) async {
    expect(method, movesense.MdsRequestMethod.get);
    requestedUri = uri;
    return movesense.MdsResponse(
      body: File('packages/carp_movesense_package/test/json/info.json').readAsStringSync(),
      statusCode: 200,
    );
  }
}

class _WatchManager extends AppleWatchDeviceManager {
  final batches = StreamController<AppleWatchRecords>();

  @override
  Stream<AppleWatchRecords> get records => batches.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();
  SamplingPackageRegistry().register(MovesenseSamplingPackage());
  SamplingPackageRegistry().register(AppleWatchSamplingPackage());

  test('CARP Movesense device probe requests info through movesense_plus', () async {
    final platform = _MovesensePlatform();
    final previous = MovesensePlatform.instance;
    MovesensePlatform.instance = platform;
    addTearDown(() => MovesensePlatform.instance = previous);
    final manager = MovesenseDeviceManager(MovesenseDevice.DEVICE_TYPE)
      ..serial = '123'
      ..status = DeviceStatus.connected;
    final probe = MovesenseDeviceProbe()..deviceManager = manager;

    final measurement = await probe.getMeasurement();
    expect(platform.requestedUri, 'suunto://123/Info');
    expect(measurement!.data, isA<MovesenseDeviceInformation>());
    expect(jsonEncode(measurement), contains('H4'));
  });

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
