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
  // Android 14+ kills the app if the location-type foreground service starts
  // without location granted, so that is required too.
  List<Permission> get _permissions =>
      _isAndroid ? [Permission.ignoreBatteryOptimizations, Permission.location] : [Permission.locationAlways];

  Future<bool> get _isGranted async {
    for (final permission in _permissions) {
      if (!await permission.isGranted) return false;
    }
    return true;
  }

  /// Re-read the platform permissions and bring the service in line with them.
  Future<void> refresh() async {
    var connected = isSupported && await _isGranted;

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

    await _permissions.request();
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
