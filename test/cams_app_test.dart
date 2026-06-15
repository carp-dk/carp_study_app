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
    // Fixtures are real study protocols with the apiKey fields blanked.
    SmartphoneStudyProtocol parse(String path) =>
        SmartphoneStudyProtocol.fromJson(json.decode(File(path).readAsStringSync()) as Map<String, dynamic>);

    // CAMS 2.x must parse protocols serialized under the old (CAMS 1.x) device
    // namespace 'dk.cachet.carp.common.application.devices.*', resolved via the
    // aliases registered in Sensing. The configurations repo still generates
    // protocols with CAMS 1.x, so this is the format the app receives today.
    test('parses a CAMS 1.x protocol (old device namespace)', () {
      final protocol = parse('test/json/protocol_cams_1x.json');

      expect(protocol.primaryDevices, isNotEmpty);
      expect(protocol.connectedDevices, isNotEmpty);
      expect(protocol.tasks, isNotEmpty);
    });

    // ...and natively under the CAMS 2.x namespace 'dk.carp.cams.devices.*'.
    test('parses a CAMS 2.x protocol (new device namespace)', () {
      final protocol = parse('test/json/protocol_cams_2x.json');

      expect(protocol.primaryDevices, isNotEmpty);
      expect(protocol.connectedDevices, isNotEmpty);
      expect(protocol.tasks, isNotEmpty);
    });
  });
}
