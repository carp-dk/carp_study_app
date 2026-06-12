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

/// App-wide configuration parsed from compile-time environment variables.
///
/// Deliberately dependency-free so that lower layers ([Sensing], [CarpBackend])
/// can read configuration without depending on the global [bloc].
///
/// The configuration is set using two environment variables:
///
///  * `deployment-mode` sets the [DeploymentMode].
///  * `debug-level` sets the [DebugLevel].
///
/// In Flutter these environment variables are set by specifying the `--dart-define`
/// option in `flutter run`. For example:
///
///  `flutter run --dart-define=deployment-mode=local,debug-level=info`
class AppConfig {
  static final AppConfig _instance = AppConfig._();
  factory AppConfig() => _instance;

  AppConfig._() {
    const dep = String.fromEnvironment('deployment-mode', defaultValue: 'production');
    deploymentMode = DeploymentMode.values.firstWhere((mode) => mode.name == dep);

    const deb = String.fromEnvironment('debug-level', defaultValue: 'info');
    debugLevel = DebugLevel.values.firstWhere((level) => level.name == deb);
  }

  /// What kind of deployment are we running?
  late DeploymentMode deploymentMode;

  /// Debug level for the app and CAMS.
  late DebugLevel debugLevel;

  /// The localization (language) of this app.
  RPLocalizations? localization;
}
