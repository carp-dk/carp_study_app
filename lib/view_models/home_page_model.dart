part of carp_study_app;

/// The 3-state connection summary shown on the home page.
enum HomeConnectionState { all, partial, none }

/// The view model for the [HomePage].
///
/// Owns the home page's service-backed, reactive data: the connection summary
/// (deployment devices minus the phone), whether an app update is available, and
/// the one-shot Health Connect install prompt. The UI reads these and rebuilds
/// via [ListenableBuilder]; it never touches the services or streams directly.
class HomePageViewModel extends ViewModel {
  HomePageViewModel({SystemInfoService? systemInfoService, StudyService? studyService})
    : _systemInfoService = systemInfoService,
      _studyService = studyService;

  final SystemInfoService? _systemInfoService;
  final StudyService? _studyService;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;
  StudyService get _study => _studyService ?? bloc.study;

  /// Per-survey completion counts for the "Completed Surveys" card.
  final TaskCardViewModel surveys = TaskCardViewModel(AppTask.SURVEY_TYPE);

  bool _healthConnectPromptPending = false;
  bool _appUpdateAvailable = false;
  List<DeviceViewModel> _connectionSources = const [];
  final List<StreamSubscription<DeviceStatus>> _deviceSubs = [];
  StreamSubscription<UserTask>? _userTaskSub;
  bool _blocAttached = false;

  /// The number of days the user has been part of the study.
  int get daysInStudy => (_study.cachedDeploymentStatus != null)
      ? DateTime.now().difference(_study.cachedDeploymentStatus!.createdOn).inDays
      : 0;

  /// The number of tasks completed so far.
  int get taskCompleted => AppTaskController().userTaskQueue.where((task) => task.state == UserTaskState.done).length;

  /// The total number of tasks issued so far.
  int get taskTotal => AppTaskController().userTaskQueue.length;

  /// The deployment status of this study, or null if not deployed yet.
  StudyDeploymentStatusTypes? get deploymentStatus =>
      _study.cachedDeploymentStatus == null ? null : _study.cachedDeploymentStatus!.status ?? StudyDeploymentStatusTypes.Invited;

  /// Should the user be prompted to install Health Connect?
  /// One-shot - the shell calls [healthConnectPromptShown] once shown.
  bool get shouldPromptHealthConnectInstall => _healthConnectPromptPending;

  void healthConnectPromptShown() => _healthConnectPromptPending = false;

  /// Is a newer version of this app available? Checked once on [init].
  bool get appUpdateAvailable => _appUpdateAvailable;

  /// Open this app's store listing.
  Future<void> openAppStore() => _system.openAppStore();

  /// The connectable data sources of this deployment (everything but the phone).
  List<DeviceViewModel> get connectionSources => _connectionSources;
  bool isSourceActive(DeviceViewModel d) => d.status == DeviceStatus.connected;
  int get totalSourceCount => _connectionSources.length;
  int get activeSourceCount => _connectionSources.where(isSourceActive).length;

  HomeConnectionState get connectionState {
    final active = activeSourceCount;
    if (active == 0) return HomeConnectionState.none;
    return active >= totalSourceCount ? HomeConnectionState.all : HomeConnectionState.partial;
  }

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _attachToBloc();
    _syncSources();
    _userTaskSub = AppTaskController().userTaskEvents.listen((_) => notifyListeners());
    unawaited(_checkHealthConnectInstallation());
    unawaited(_checkAppUpdate());
    unawaited(_refreshDeploymentStatus());
  }

  // The cached status is only filled by an explicit refresh; without this the
  // status card stays hidden and daysInStudy is 0.
  Future<void> _refreshDeploymentStatus() async {
    try {
      await _study.refreshDeploymentStatus();
    } catch (error) {
      warning('$runtimeType - could not refresh deployment status - $error');
    }
    notifyListeners();
  }

  // Re-read the device list whenever the bloc notifies (e.g. configuration
  // completing). Device managers register asynchronously, so the initial sync
  // in init() is usually empty; this is what fills the summary in later.
  void _attachToBloc() {
    if (_blocAttached) return;
    _blocAttached = true;
    bloc.addListener(_syncSources);
  }

  void _syncSources() {
    final sources = _study.deploymentDevices.where((d) => d.deviceManager is! SmartphoneDeviceManager).toList();
    _cancelDeviceSubs();
    // Subscribe to the durable device-manager stream directly, so the ephemeral
    // DeviceViewModel wrappers from deploymentDevices don't matter.
    for (final s in sources) {
      _deviceSubs.add(s.statusEvents.listen((_) => notifyListeners()));
    }
    _connectionSources = sources;
    notifyListeners();
  }

  void _cancelDeviceSubs() {
    for (final s in _deviceSubs) {
      s.cancel();
    }
    _deviceSubs.clear();
  }

  Future<void> _checkAppUpdate() async {
    try {
      _appUpdateAvailable = await _system.getAppHasUpdate() ?? false;
    } catch (_) {
      _appUpdateAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _checkHealthConnectInstallation() async {
    if (!Platform.isAndroid) return;
    if (await _system.isHealthInstalled()) return;
    _healthConnectPromptPending = true;
    notifyListeners();
  }

  @override
  void clear() {
    _cancelDeviceSubs();
    _connectionSources = const [];
    _healthConnectPromptPending = false;
    _appUpdateAvailable = false;
    super.clear();
  }

  @override
  void dispose() {
    if (_blocAttached) bloc.removeListener(_syncSources);
    _cancelDeviceSubs();
    _userTaskSub?.cancel();
    super.dispose();
  }
}
