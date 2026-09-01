part of carp_study_app;

/// Keeps data collection running while the app is in the background.
/// Not part of the deployment - the user connects to it, the app resumes it.
///
/// On Android that is a foreground service, gated by the battery optimization
/// exemption. On iOS there is no such service - continuous location updates
/// keep the app alive, which needs the "Always" location permission; the
/// sampling packages already enable background location updates themselves.
class BackgroundSensingService extends ChangeNotifier {
  static final BackgroundSensingService _instance = BackgroundSensingService._();
  factory BackgroundSensingService() => _instance;
  BackgroundSensingService._();

  bool _isConnected = false;

  /// Is background sensing running?
  bool get isConnected => _isConnected;

  /// Tests override via [debugDefaultTargetPlatformOverride].
  bool get isSupported => _isAndroid || defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  // The exemption (Android) or Always location (iOS) is the truth - both can
  // be revoked in the phone's settings at any time, so re-read, not remembered.
  Permission get _permission => _isAndroid ? Permission.ignoreBatteryOptimizations : Permission.locationAlways;

  /// Re-read the platform permission and bring the service in line with it.
  Future<void> refresh() async {
    var connected = isSupported && await _permission.isGranted;

    // The foreground service exists only on Android; on iOS the granted
    // permission is all there is - location updates keep sensing alive.
    if (_isAndroid) {
      if (connected && !BackgroundService().isEnabled) connected = await _start();
      // Revoked while running - the exemption is gone, so stop the service too.
      if (!connected && BackgroundService().isEnabled) await BackgroundService().disable();
    }

    if (connected != _isConnected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  /// Ask for the platform permission and start sensing in background.
  Future<void> connect() async {
    if (!isSupported) return;

    await _permission.request();
    await refresh();
  }

  /// Stop background sensing - there is nothing to sense without a study.
  Future<void> disconnect() async {
    if (!_isConnected) return;

    if (_isAndroid) await BackgroundService().disable();
    _isConnected = false;
    notifyListeners();
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
