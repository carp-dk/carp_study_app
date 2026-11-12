import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('study startup does not request all permissions', () {
    final sensing = File('lib/core/sensing/sensing.dart').readAsStringSync();
    expect(sensing, contains('askForPermissions: false,'));
  });

  test('Android declares the sleep read permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.health.READ_SLEEP'));
  });
}
