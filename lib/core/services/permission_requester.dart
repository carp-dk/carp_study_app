import 'package:flutter/foundation.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:research_package/research_package.dart';

/// Asks the OS for the permissions of the consent sections (`askPermission` in consent.json).
/// research_package 4 does not ask itself - see [RPPermissions.requester].
Future<RPPermissionStatus> requestPermission(RPPermissionType type, {List<String> healthDataTypes = const []}) async {
  final android = defaultTargetPlatform == TargetPlatform.android;
  switch (type) {
    case RPPermissionType.health:
      return requestHealth(healthDataTypes);
    case RPPermissionType.ignoreBatteryOptimizations when !android:
      return RPPermissionStatus.unsupported; // iOS: background modes, nothing to ask
    case RPPermissionType.locationAlways:
      // Background location needs the foreground one first.
      final foreground = statusOf(await ph.Permission.locationWhenInUse.request());
      if (foreground != RPPermissionStatus.granted) return foreground;
      return statusOf(await ph.Permission.locationAlways.request());
    case RPPermissionType.bluetooth when android:
      // Android 12+ "Nearby devices" - one dialog for both.
      final statuses = await [ph.Permission.bluetoothScan, ph.Permission.bluetoothConnect].request();
      return statuses.values
          .map(statusOf)
          .firstWhere((s) => s != RPPermissionStatus.granted, orElse: () => RPPermissionStatus.granted);
    default:
      return statusOf(await permissionOf(type).request());
  }
}

/// Read access to the [names] of health data types, e.g. `'STEPS'`. Unknown names are skipped.
/// On iOS `granted` only means the sheet was shown - HealthKit hides read access.
Future<RPPermissionStatus> requestHealth(List<String> names) async {
  final byName = HealthDataType.values.asNameMap();
  final types = [for (final name in names) ?byName[name]];
  if (types.isEmpty) return RPPermissionStatus.unsupported;
  final health = Health();
  // requestAuthorization can block when everything is granted already; null on iOS = undetermined.
  if (await health.hasPermissions(types) ?? false) return RPPermissionStatus.granted;
  return await health.requestAuthorization(types) ? RPPermissionStatus.granted : RPPermissionStatus.denied;
}

@visibleForTesting
ph.Permission permissionOf(RPPermissionType type) => switch (type) {
  RPPermissionType.location => ph.Permission.locationWhenInUse,
  RPPermissionType.locationAlways => ph.Permission.locationAlways,
  RPPermissionType.microphone => ph.Permission.microphone,
  RPPermissionType.camera => ph.Permission.camera,
  RPPermissionType.notification => ph.Permission.notification,
  // iOS has no activity recognition permission - the data comes from CoreMotion.
  RPPermissionType.activityRecognition =>
    defaultTargetPlatform == TargetPlatform.iOS ? ph.Permission.sensors : ph.Permission.activityRecognition,
  RPPermissionType.sensors => ph.Permission.sensors,
  RPPermissionType.bluetooth => ph.Permission.bluetooth,
  RPPermissionType.ignoreBatteryOptimizations => ph.Permission.ignoreBatteryOptimizations,
  RPPermissionType.health => throw UnsupportedError('health is not a platform permission'),
};

@visibleForTesting
RPPermissionStatus statusOf(ph.PermissionStatus status) => switch (status) {
  // Partial access (some photos, provisional notifications) still counts.
  ph.PermissionStatus.granted ||
  ph.PermissionStatus.limited ||
  ph.PermissionStatus.provisional => RPPermissionStatus.granted,
  ph.PermissionStatus.denied => RPPermissionStatus.denied,
  ph.PermissionStatus.permanentlyDenied => RPPermissionStatus.permanentlyDenied,
  ph.PermissionStatus.restricted => RPPermissionStatus.restricted,
};
