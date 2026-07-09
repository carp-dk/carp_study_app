part of carp_study_app;

/// The view model for the [HomePage].
class HomePageViewModel extends ViewModel {
  HomePageViewModel({SystemInfoService? systemInfoService}) : _systemInfoService = systemInfoService;

  final SystemInfoService? _systemInfoService;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;

  bool _healthConnectPromptPending = false;

  /// Should the user be prompted to install Health Connect?
  /// One-shot - the page calls [healthConnectPromptShown] once shown.
  bool get shouldPromptHealthConnectInstall => _healthConnectPromptPending;

  void healthConnectPromptShown() => _healthConnectPromptPending = false;

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    unawaited(_checkHealthConnectInstallation());
  }

  Future<void> _checkHealthConnectInstallation() async {
    if (!Platform.isAndroid) return;
    if (await _system.isHealthInstalled()) return;
    _healthConnectPromptPending = true;
    notifyListeners();
  }

  @override
  void clear() {
    _healthConnectPromptPending = false;
    super.clear();
  }
}
