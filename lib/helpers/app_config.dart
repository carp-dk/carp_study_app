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

/// App-wide configuration parsed once from compile-time environment variables.
///
/// A static, dependency-free holder so that lower layers ([Sensing],
/// [CarpBackend]) can read configuration without depending on the global
/// [bloc] - and without anything needing to instantiate it.
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
///
/// Note: `String.fromEnvironment` only reads the `--dart-define` value in a
/// const context, hence the explicit `const` below.
abstract class AppConfig {
  /// What kind of deployment are we running?
  static DeploymentMode deploymentMode = DeploymentMode.values.firstWhere(
    (mode) => mode.name == const String.fromEnvironment('deployment-mode', defaultValue: 'production'),
  );

  /// Debug level for the app and CAMS.
  static DebugLevel debugLevel = DebugLevel.values.firstWhere(
    (level) => level.name == const String.fromEnvironment('debug-level', defaultValue: 'info'),
  );

  /// The localization (language) of this app.
  static RPLocalizations? localization;

  /// Fill the statistics charts with [DemoChartData] while the study has
  /// collected nothing of its own.
  ///
  /// Never on a production deployment - a participant must only ever be shown
  /// their own data.
  // ponytail: temporary, so the charts can be designed before devices report.
  // Delete this and demo_chart_data.dart once they do.
  static bool get useDemoChartData => deploymentMode != DeploymentMode.production;
}
