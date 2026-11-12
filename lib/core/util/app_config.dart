import 'package:flutter/foundation.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:research_package/research_package.dart';

/// How to deploy a study.
enum DeploymentMode {
  /// Use a local study protocol & deployment and store data locally on the phone.
  local,

  /// Use the CAWS production server to get the study deployment and store data.
  production,

  /// Use the CAWS test server to get the study deployment and store data.
  test,

  /// Use the CAWS development server to get the study deployment and store data.
  dev,
}

/// App-wide configuration from `--dart-define` variables `deployment-mode`,
/// `debug-level` and `skip-consent`, e.g. `flutter run --dart-define=deployment-mode=dev`.
/// (`String.fromEnvironment` only reads them in a const context.)
abstract class AppConfig {
  /// What kind of deployment are we running?
  ///
  /// Defaults to [DeploymentMode.local] in debug builds, so a plain `flutter run`
  /// runs the study in `assets/carp`, and to [DeploymentMode.production] in release builds.
  static DeploymentMode deploymentMode = DeploymentMode.values.firstWhere(
    (mode) =>
        mode.name == const String.fromEnvironment('deployment-mode', defaultValue: kDebugMode ? 'local' : 'production'),
  );

  /// Debug level for the app and CAMS.
  static DebugLevel debugLevel = DebugLevel.values.firstWhere(
    (level) => level.name == const String.fromEnvironment('debug-level', defaultValue: 'info'),
  );

  /// Skip the informed consent flow, e.g. `--dart-define=skip-consent=true`.
  /// Local mode only - a study on CAWS always asks for consent.
  static bool get skipConsent => deploymentMode == DeploymentMode.local && const bool.fromEnvironment('skip-consent');

  /// The localization (language) of this app.
  static RPLocalizations? localization;
}
