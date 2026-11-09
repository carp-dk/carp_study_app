part of carp_study_app;

/// Device- and platform-level checks: connectivity, installed apps, and
/// app-store updates.
class SystemInfoService {
  SystemInfoService({AppCheck? appCheck, Connectivity? connectivity})
    : _appCheck = appCheck ?? AppCheck(),
      _connectivity = connectivity ?? Connectivity();

  final AppCheck _appCheck;
  final Connectivity _connectivity;

  /// Is the phone connected to the internet?
  ///
  /// Any active interface counts as connected. We deliberately do NOT restrict
  /// to wifi/mobile: the iOS Simulator, desktops, and wired setups report
  /// `ethernet`/`vpn`/`other` while still having working internet, so limiting
  /// to wifi/mobile falsely reports "offline".
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Check if the Health database is installed on this phone.
  ///
  /// Always returns true on iOS, since Health is part of the OS and hence always installed.
  /// On Android, returns true if Google Health Connect is installed, false otherwise.
  Future<bool> isHealthInstalled() async {
    if (Platform.isIOS) return true;

    try {
      return await _appCheck.isAppInstalled(LocalSettings.healthConnectPackageName);
    } catch (e) {
      debug("$runtimeType - Error checking Health Connect installation: $e");
      return false;
    }
  }

  /// Is a newer version of this app available in the app store?
  Future<bool?> getAppHasUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    AppVersionResult result = await AppVersionUpdate.checkForUpdates(
      playStoreId: packageInfo.packageName,
      appleId: '1569798025',
      country: 'dk',
    );
    return result.canUpdate;
  }

  /// Open this app's store listing (Play Store on Android, App Store on iOS).
  Future<void> openAppStore() async {
    final info = await PackageInfo.fromPlatform();
    final url = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/apps/details?id=${info.packageName}')
        : Uri.parse('https://apps.apple.com/app/1569798025');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
