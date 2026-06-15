import 'dart:convert';
import 'dart:io';

import 'package:carp_backend/carp_backend.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';

import 'exports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    CarpDataManager();

    // Register exactly what the app registers - sampling packages plus the
    // old-namespace device aliases - so these tests exercise the real
    // deserialization path. See Sensing.
    Sensing();
  });

  group("Study protocol deserialization", () {
    SmartphoneStudyProtocol parse(String path) =>
        SmartphoneStudyProtocol.fromJson(json.decode(File(path).readAsStringSync()) as Map<String, dynamic>);

    // SKIPPED: the 1.x/2.x protocol fixtures were removed because the source
    // demo protocol embeds live WeatherService/AirQualityService API keys.
    // Re-enable once key-free fixtures are committed (regenerate with the
    // apiKey fields blanked).
    test('parses a CAMS 1.x protocol (old device namespace)', skip: true, () {
      final protocol = parse('test/json/protocol_cams_1x.json');

      expect(protocol.primaryDevices, isNotEmpty);
      expect(protocol.connectedDevices, isNotEmpty);
      expect(protocol.tasks, isNotEmpty);
    });

    test('parses a CAMS 2.x protocol (new device namespace)', skip: true, () {
      final protocol = parse('test/json/protocol_cams_2x.json');

      expect(protocol.primaryDevices, isNotEmpty);
      expect(protocol.connectedDevices, isNotEmpty);
      expect(protocol.tasks, isNotEmpty);
    });
  });
}
