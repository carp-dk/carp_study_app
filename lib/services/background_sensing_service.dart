part of carp_study_app;

/// Keeps data collection running while the app is in the background.
/// Not part of the deployment - the user connects to it, the app resumes it.
///
/// On Android that is a foreground service, gated by the battery optimization
/// exemption. On iOS it is only the UIBackgroundModes flag in Info.plist, so it
/// is always on - location measures ask for "Always" location themselves.
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

  // The exemption is the truth - it can be revoked in the phone's settings at
  // any time, so re-read, not remembered. Android 14+ kills the app if the
  // location-type foreground service starts without location granted.
  static const List<Permission> _permissions = [Permission.ignoreBatteryOptimizations, Permission.location];

  Future<bool> get _isGranted async {
    for (final permission in _permissions) {
      if (!await permission.isGranted) return false;
    }
    return true;
  }

  /// Re-read the platform permissions and bring the service in line with them.
  Future<void> refresh() async {
    // iOS: nothing to start or grant - the Info.plist flag is all there is.
    var connected = defaultTargetPlatform == TargetPlatform.iOS || (_isAndroid && await _isGranted);

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

  /// Ask for the exemption and start sensing in background.
  Future<void> connect() async {
    if (!isSupported) return;

    if (_isAndroid) await _permissions.request();
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
