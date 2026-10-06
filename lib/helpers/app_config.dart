part of carp_study_app;

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

/// App-wide configuration from `--dart-define` variables `deployment-mode`
/// and `debug-level`, e.g. `flutter run --dart-define=deployment-mode=dev`.
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

  /// The localization (language) of this app.
  static RPLocalizations? localization;
}
