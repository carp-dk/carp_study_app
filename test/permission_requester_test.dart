import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/services/permission_requester.dart';

void main() {
  test('partial access counts as granted', () {
    expect(statusOf(ph.PermissionStatus.limited), RPPermissionStatus.granted);
    expect(statusOf(ph.PermissionStatus.provisional), RPPermissionStatus.granted);
    expect(statusOf(ph.PermissionStatus.permanentlyDenied), RPPermissionStatus.permanentlyDenied);
  });

  test('activity recognition is sensors on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(permissionOf(RPPermissionType.activityRecognition), ph.Permission.sensors);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(permissionOf(RPPermissionType.activityRecognition), ph.Permission.activityRecognition);
    debugDefaultTargetPlatformOverride = null;
  });

  test('health without known data types asks nothing', () async {
    expect(await requestHealth(['NOT_A_TYPE']), RPPermissionStatus.unsupported);
  });

  test('research_package asks through our requester', () async {
    ResearchPackage.ensureInitialized(permissionRequester: requestPermission);
    expect(RPPermissions.requester, requestPermission);
    // iOS has no battery optimisation dialog - answered without a platform call.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await RPPermissions.request(RPPermissionType.ignoreBatteryOptimizations), RPPermissionStatus.unsupported);
    debugDefaultTargetPlatformOverride = null;
  });
}
