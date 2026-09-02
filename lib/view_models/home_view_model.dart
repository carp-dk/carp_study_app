part of carp_study_app;

/// The 3-state connection summary shown on the home page.
enum HomeConnectionState { all, partial, none }

/// View model for [HomePage] and [CarpAppShell] - everything the home tab shows.
class HomePageViewModel extends ViewModel {
  HomePageViewModel({SystemInfoService? systemInfoService, StudyService? studyService, MessageService? messageService})
    : _systemInfoService = systemInfoService,
      _studyService = studyService,
      _messageService = messageService;

  final SystemInfoService? _systemInfoService;
  final StudyService? _studyService;
  final MessageService? _messageService;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;
  StudyService get _study => _studyService ?? bloc.study;
  MessageService get _messages => _messageService ?? bloc.messages;

  bool _healthConnectPromptPending = false;
  bool _appUpdateAvailable = false;
  List<DeviceViewModel> _connectionSources = const [];
  final List<StreamSubscription<DeviceStatus>> _deviceSubs = [];
  StreamSubscription<UserTask>? _userTaskSub;
  StreamSubscription<int>? _messageSub;
  bool _blocAttached = false;

  /// The announcements/news shown in the "Feeds" section, newest first.
  List<Message> get messages => _messages.messages;

  /// Is the study loaded? Waits for the status too, so the card renders in one go.
  bool get isLoaded =>
      (_study.deployment?.studyDescription?.title ?? '').isNotEmpty && _study.cachedDeploymentStatus != null;

  /// The title and description of this study, shown on the home about card.
  String get studyTitle => _study.deployment?.studyDescription?.title ?? '';
  String get studyDescription => _study.deployment?.studyDescription?.description ?? '';

  // The distinct calendar days on which the user completed at least one task.
  Set<String> get _activeDays => AppTaskController().userTaskQueue
      .where((task) => task.state == UserTaskState.done && task.doneTime != null)
      .map((task) => _dayKey(task.doneTime!.toLocal()))
      .toSet();

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// The number of days on which the user completed at least one task.
  int get activeDaysInStudy => _activeDays.length;

  /// The last 7 days, oldest first - true if a task was completed that day.
  List<bool> get lastWeekActivity {
    final done = _activeDays;
    final today = DateTime.now();
    return List.generate(7, (i) => done.contains(_dayKey(today.subtract(Duration(days: 6 - i)))));
  }

  /// The number of tasks completed so far.
  int get taskCompleted => AppTaskController().userTaskQueue.where((task) => task.state == UserTaskState.done).length;

  /// The number of tasks still available for the user to do.
  int get taskPending => AppTaskController().userTaskQueue.where((task) => task.availableForUser).length;

  /// The deployment status of this study, or null if not deployed yet.
  StudyDeploymentStatusTypes? get deploymentStatus => _study.cachedDeploymentStatus == null
      ? null
      : _study.cachedDeploymentStatus!.status ?? StudyDeploymentStatusTypes.Invited;

  /// Prompt to install Health Connect? One-shot, via [healthConnectPromptShown].
  bool get shouldPromptHealthConnectInstall => _healthConnectPromptPending;

  void healthConnectPromptShown() => _healthConnectPromptPending = false;

  /// Is a newer version of this app available? Checked once on [init].
  bool get appUpdateAvailable => _appUpdateAvailable;

  /// Open this app's store listing.
  Future<void> openAppStore() => _system.openAppStore();

  /// The connectable data sources of this deployment (everything but the phone).
  List<DeviceViewModel> get connectionSources => _connectionSources;
  bool isSourceActive(DeviceViewModel d) => d.status == DeviceStatus.connected;

  /// Background sensing counts too - without it, data only flows in foreground.
  bool get hasBackgroundSensing => BackgroundSensingService().isSupported;
  bool get isBackgroundSensingActive => BackgroundSensingService().isConnected;

  int get totalSourceCount => _connectionSources.length + (hasBackgroundSensing ? 1 : 0);
  int get activeSourceCount => _connectionSources.where(isSourceActive).length + (isBackgroundSensingActive ? 1 : 0);

  HomeConnectionState get connectionState {
    final active = activeSourceCount;
    if (active == 0) return HomeConnectionState.none;
    return active >= totalSourceCount ? HomeConnectionState.all : HomeConnectionState.partial;
  }

  /// Deploy the study - this page is the first shown once consent is in place.
  Future<void> configureStudy() => bloc.tryConfigureStudy();

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _attachToBloc();
    _syncSources();
    _userTaskSub = AppTaskController().userTaskEvents.listen((_) => notifyListeners());
    _messageSub = _messages.stream.listen((_) => notifyListeners());
    unawaited(_checkHealthConnectInstallation());
    unawaited(_checkAppUpdate());
    unawaited(_refreshDeploymentStatus());
  }

  // The cached status is only filled by an explicit refresh.
  Future<void> _refreshDeploymentStatus() async {
    try {
      await _study.refreshDeploymentStatus();
    } catch (error) {
      warning('$runtimeType - could not refresh deployment status - $error');
    }
    notifyListeners();
  }

  // Device managers register async, so init()'s list is empty - this fills it.
  void _attachToBloc() {
    if (_blocAttached) return;
    _blocAttached = true;
    bloc.addListener(_syncSources);
  }

  void _syncSources() {
    final sources = _study.deploymentDevices.where((d) => d.deviceManager is! SmartphoneDeviceManager).toList();
    _cancelDeviceSubs();
    // The durable manager stream, not the per-call DeviceViewModel wrappers.
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
    _messageSub?.cancel();
    super.dispose();
  }
}
