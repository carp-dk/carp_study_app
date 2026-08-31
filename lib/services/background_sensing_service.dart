part of carp_study_app;

/// The Android foreground service keeping data collection running in background.
/// Not part of the deployment - the user connects to it, the app resumes it.
class BackgroundSensingService extends ChangeNotifier {
  static final BackgroundSensingService _instance = BackgroundSensingService._();
  factory BackgroundSensingService() => _instance;
  BackgroundSensingService._();

  bool _isConnected = false;

  /// Is background sensing running?
  bool get isConnected => _isConnected;

  /// Android only - tests override via [debugDefaultTargetPlatformOverride].
  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Re-read the battery exemption - the truth, and it can be revoked any time.
  Future<void> refresh() async {
    var connected = isSupported && await Permission.ignoreBatteryOptimizations.isGranted;
    if (connected && !BackgroundService().isEnabled) connected = await _start();

    if (connected != _isConnected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  /// Ask for the battery optimization exemption and start sensing in background.
  Future<void> connect() async {
    if (!isSupported) return;

    await Permission.ignoreBatteryOptimizations.request();
    await refresh();
  }

  Future<bool> _start() async {
    final localization = AppConfig.localization;
    return await BackgroundService().initialize(
          notificationTitle: localization?.translate('pages.devices.type.background.name'),
          notificationText: localization?.translate('pages.devices.type.background.description'),
        ) &&
        await BackgroundService().enable();
  }
}
