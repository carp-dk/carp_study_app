import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exports.dart';

/// Initialize CAMS [Settings] for unit tests by mocking the platform
/// channels it depends on (shared preferences, package info, paths).
Future<void> initTestSettings() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'carp_study_app_test',
    packageName: 'dk.cachet.carp_study_app.test',
    version: '0.0.0',
    buildNumber: '0',
    buildSignature: '',
  );
  PathProviderPlatform.instance = FakePathProviderPlatform();

  await Settings().init();
}

class FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  static final String _tempPath = Directory.systemTemp.createTempSync('carp_study_app_test').path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => _tempPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;

  @override
  Future<String?> getLibraryPath() async => _tempPath;
}
