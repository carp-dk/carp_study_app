import 'dart:convert';
import 'dart:io';

import 'package:carp_backend/carp_backend.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';

// Validate the ignored local configuration with:
// flutter test test/apple_watch_protocol_test.dart --dart-define=WATCH_PROTOCOL=assets/carp/resources/protocol.json
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('watch protocol connects all nine measures to an immediate watch task', () {
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    CarpDataManager();
    Sensing();
    const path = String.fromEnvironment('WATCH_PROTOCOL', defaultValue: 'test/flow/fixtures/test_study/protocol.json');
    final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final protocol = SmartphoneStudyProtocol.fromJson(json);
    final watch = protocol.connectedDevices!.whereType<AppleWatchDevice>().single;
    expect(watch.isOptional, isTrue);
    expect(watch.motionSamplingRate, 10);
    expect(watch.fileTransferInterval, const Duration(minutes: 1));
    expect(
      json['connections'],
      contains(equals({'roleName': watch.roleName, 'connectedToRoleName': protocol.primaryDevices.single.roleName})),
    );

    final tasks = json['tasks'] as List;
    final triggers = json['triggers'] as Map;
    final measures = <String>{};
    for (final control in json['taskControls'] as List) {
      if (control['destinationDeviceRoleName'] != watch.roleName) continue;
      final task = tasks.singleWhere((task) => task['name'] == control['taskName']);
      final trigger = triggers[control['triggerId'].toString()] as Map;
      if (!(trigger['__type'] as String).endsWith('.ImmediateTrigger')) continue;
      expect(trigger['sourceDeviceRoleName'], watch.roleName);
      expect(control['control'], 'Start');
      measures.addAll((task['measures'] as List).map((m) => m['type'] as String));
    }
    expect(measures, {
      AppleWatchSamplingPackage.MOTION,
      AppleWatchSamplingPackage.HEART_RATE,
      AppleWatchSamplingPackage.BATTERY,
      AppleWatchSamplingPackage.LOCATION,
      AppleWatchSamplingPackage.HEADING,
      AppleWatchSamplingPackage.BLUETOOTH,
      AppleWatchSamplingPackage.AMBIENT_NOISE,
      AppleWatchSamplingPackage.AUDIO_LABEL,
      AppleWatchSamplingPackage.DEVICE,
    });
  });
}
