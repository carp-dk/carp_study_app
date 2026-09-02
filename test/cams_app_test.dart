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

    // The demo protocol's devices, by concrete runtime class and role name.
    // Asserting the runtime type (not just "non-empty") is what proves each
    // device's '__type' resolved to its real class - via the Sensing aliases
    // for the 1.x namespace, and natively for 2.x. A regression in either path
    // would surface as a missing/wrong type here (or a SerializationException).
    const expectedConnectedTypes = {
      'LocationService',
      'WeatherService',
      'AirQualityService',
      'HealthService',
      'PolarDevice',
      'MovesenseDevice',
    };
    const expectedConnectedRoles = {
      'Location Service',
      'Weather Service',
      'Air Quality Service',
      'Health Service',
      'Polar HR Sensor',
      'Movesense ECG Device',
    };

    // The data-collection (Measure) types the protocol declares across all
    // tasks - the sensors/services actually sampled, plus CAMS control types.
    const expectedDataTypes = {
      // device & sensor sampling
      'dk.cachet.carp.ambientlight',
      'dk.cachet.carp.stepcount',
      'dk.cachet.carp.freememory',
      'dk.cachet.carp.deviceinformation',
      'dk.cachet.carp.batterystate',
      'dk.cachet.carp.screenevent',
      'dk.cachet.carp.activity',
      // context services
      'dk.cachet.carp.location',
      'dk.cachet.carp.mobility',
      'dk.cachet.carp.weather',
      'dk.cachet.carp.airquality',
      // wearables
      'dk.cachet.carp.polar.hr',
      'dk.cachet.carp.movesense.hr',
      'dk.cachet.carp.movesense.state',
      // health
      'dk.cachet.carp.health',
      // app tasks / media / survey
      'dk.cachet.carp.audio',
      'dk.cachet.carp.image',
      'dk.cachet.carp.survey',
      // CAMS control & app-task lifecycle
      'dk.cachet.carp.error',
      'dk.cachet.carp.heartbeat',
      'dk.cachet.carp.triggeredtask',
      'dk.cachet.carp.completedtask',
      'dk.cachet.carp.completedapptask',
    };

    void expectDemoProtocol(SmartphoneStudyProtocol protocol) {
      // Primary device: a single Smartphone.
      expect(protocol.primaryDevices.map((d) => d.runtimeType.toString()), ['Smartphone']);
      expect(protocol.primaryDevices.single.roleName, 'Primary Phone');

      // Connected devices/services: all six resolved to their concrete classes.
      final connected = protocol.connectedDevices!;
      expect(connected.length, 6);
      expect(connected.map((d) => d.runtimeType.toString()).toSet(), expectedConnectedTypes);
      expect(connected.map((d) => d.roleName).toSet(), expectedConnectedRoles);

      // Task graph is fully parsed.
      expect(protocol.tasks.length, 21);
      expect(protocol.taskControls.length, 21);

      // Data-collection types: the protocol declares all the expected sensor/
      // service/app-task measures (it also adds dynamic per-task
      // 'completedapptask.<name>' lifecycle measures, which we don't pin), and
      // every expected type is provided by a registered sampling package - i.e.
      // the app can actually collect it. A namespace/registration regression in
      // any package would drop a type from one side or the other.
      final declaredTypes = {for (final task in protocol.tasks) ...?task.measures?.map((m) => m.type)};
      expect(declaredTypes, containsAll(expectedDataTypes));

      final supportedTypes = SamplingPackageRegistry().dataTypes.map((d) => d.type).toSet();
      expect(
        expectedDataTypes.difference(supportedTypes),
        isEmpty,
        reason: 'these declared data types are not registered in any sampling package',
      );
    }

    // CAMS 2.x must parse protocols serialized under the old (CAMS 1.x) device
    // namespace 'dk.cachet.carp.common.application.devices.*', resolved via the
    // aliases registered in Sensing. The configurations repo still generates
    // protocols with CAMS 1.x, so this is the format the app receives today.
    test('parses a CAMS 1.x protocol (old device namespace)', () {
      expectDemoProtocol(parse('test/json/protocol_cams_1x.json'));
    });

    // ...and natively under the CAMS 2.x namespace 'dk.carp.cams.devices.*'.
    test('parses a CAMS 2.x protocol (new device namespace)', () {
      expectDemoProtocol(parse('test/json/protocol_cams_2x.json'));
    });

    test('parses a bluetooth measure with its scan sampling configuration', () {
      final measure = Measure.fromJson({
        '__type': 'dk.cachet.carp.common.application.tasks.Measure.DataStream',
        'type': ConnectivitySamplingPackage.BLUETOOTH,
        'overrideSamplingConfiguration': {
          '__type': 'dk.cachet.carp.common.application.sampling.BluetoothScanPeriodicSamplingConfiguration',
          'interval': 15000000,
          'duration': 10000000,
          'withServices': <String>[],
          'withRemoteIds': <String>[],
        },
      });

      expect(measure.overrideSamplingConfiguration, isA<PeriodicSamplingConfiguration>());

      final supportedTypes = SamplingPackageRegistry().dataTypes.map((d) => d.type).toSet();
      expect(
        supportedTypes,
        containsAll([
          ConnectivitySamplingPackage.CONNECTIVITY,
          ConnectivitySamplingPackage.WIFI,
          ConnectivitySamplingPackage.BLUETOOTH,
        ]),
      );
    });
  });
}
