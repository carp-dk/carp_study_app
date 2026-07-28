part of carp_study_app;

/// The 3-state connection summary shown on the home page.
enum HomeConnectionState { all, partial, none }

/// View model for [HomePage] and [CarpAppShell].
///
/// State: whether the study is loaded, its title and status, connected devices,
/// task and active-day counts, announcements, and the app update / Health
/// Connect prompts.
///
/// Keeps that data fresh from the services and streams so the pages only read
/// and rebuild.
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

  /// Per-survey completion counts for the "Completed Surveys" card.
  final TaskCardViewModel surveys = TaskCardViewModel(AppTask.SURVEY_TYPE);

  bool _healthConnectPromptPending = false;
  bool _appUpdateAvailable = false;
  List<DeviceViewModel> _connectionSources = const [];
  final List<StreamSubscription<DeviceStatus>> _deviceSubs = [];
  StreamSubscription<UserTask>? _userTaskSub;
  StreamSubscription<int>? _messageSub;
  bool _blocAttached = false;

  /// The announcements/news shown in the "Feeds" section, newest first.
  List<Message> get messages => _messages.messages;

  /// Is the study (and thus the home page content) loaded? Until then the
  /// page shows a shimmer skeleton. Waits for both the study description and
  /// the deployment status, so the about card (incl. its status bubble)
  /// renders complete in one go instead of growing when the status lands.
  bool get isLoaded =>
      (_study.deployment?.studyDescription?.title ?? '').isNotEmpty && _study.cachedDeploymentStatus != null;

  /// The title and description of this study, shown on the home about card.
  String get studyTitle => _study.deployment?.studyDescription?.title ?? '';
  String get studyDescription => _study.deployment?.studyDescription?.description ?? '';

  // The distinct calendar days on which the user completed at least one task.
  Set<String> get _activeDays => AppTaskController()
      .userTaskQueue
      .where((task) => task.state == UserTaskState.done && task.doneTime != null)
      .map((task) => _dayKey(task.doneTime!.toLocal()))
      .toSet();

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// The number of days on which the user completed at least one task.
  int get activeDaysInStudy => _activeDays.length;

  /// Task activity for the last 7 days (oldest first) - true if at least one
  /// task was completed that day.
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
    _messageSub = _messages.stream.listen((_) => notifyListeners());
    unawaited(_checkHealthConnectInstallation());
    unawaited(_checkAppUpdate());
    unawaited(_refreshDeploymentStatus());
  }

  // The cached status is only filled by an explicit refresh; without this the
  // status card stays hidden.
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
    _messageSub?.cancel();
    super.dispose();
  }
}
