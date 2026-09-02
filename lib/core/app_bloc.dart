part of carp_study_app;

/// The [AppBloc] state, ordered by progress - a state implies the ones before it.
enum AppState {
  /// The BLoC is created but not ready for use.
  created,

  /// The BLoC is initialized via the [initialized] method.
  initialized,

  /// Configuration failed - recover by calling [AppBloc.tryConfigureStudy] again.
  configurationFailed,

  /// The BLoC is in the process of being configured with a study.
  configuring,

  /// The BLoC is configured with a study and ready to use.
  configured,
}

/// The app coordinator: state machine, services, and orchestration. See `bloc`.
class AppBloc extends ChangeNotifier {
  AppState _state = AppState.created;
  final AppViewModel _appViewModel = AppViewModel();
  StreamSubscription<UserTask>? _userTaskNotificationSubscription;

  /// The resource managers matching the current deployment mode.
  late final ResourceManagerFactory resources = ResourceManagerFactory();

  /// Device- and platform-level checks.
  late final SystemInfoService system = SystemInfoService();

  /// User identity and authentication.
  late final AuthService auth = AuthService();

  /// The study running on this phone and its deployment.
  late final StudyService study = StudyService(resources: resources);

  /// The messages shown in the app, kept refreshed by polling.
  late final MessageService messages = MessageService(resources.messageManager);

  /// The informed consent flow.
  late final ConsentService consent = ConsentService(resources.informedConsentManager);

  /// The state of this BloC.
  AppState get state => _state;

  bool get isInitialized => _state.index >= AppState.initialized.index;
  bool get isConfiguring => _state.index >= AppState.configuring.index;
  bool get isConfigured => _state.index >= AppState.configured.index;

  /// The overall data model for this app
  AppViewModel get appViewModel => _appViewModel;

  // ScaffoldMessenger for showing snack bars
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;

  /// Create the BLoC for the app.
  AppBloc() : super() {
    info(
      '$runtimeType created. '
      'DeploymentMode: ${AppConfig.deploymentMode.name}, '
      'DebugLevel: ${AppConfig.debugLevel.name}',
    );
  }

  /// Run [configureStudy], surfacing a failure to the user instead of throwing.
  Future<void> tryConfigureStudy() async {
    try {
      await configureStudy();
    } catch (error) {
      final context = scaffoldKey.currentContext;
      final locale = context != null ? RPLocalizations.of(context) : null;
      scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(locale?.translate('pages.home.setup_failed') ?? 'Could not set up the study.')),
      );
    }
  }

  /// Did the last configuration attempt fail? Shows the error + retry card.
  bool get configurationFailed => _state == AppState.configurationFailed;

  /// Initialize this BLOC. Called before being used for anything.
  Future<void> initialize() async {
    if (isInitialized) return;

    Settings().debugLevel = AppConfig.debugLevel;
    await Settings().init();

    CarpResourceManager().initialize();

    if (AppConfig.deploymentMode != DeploymentMode.local) {
      // Offline-safe, and configures the deployment service Sensing() needs.
      await auth.initialize();
    } else {
      // Deploy the local protocol if running in local mode
      await study.deployLocalProtocol();
    }

    _state = AppState.initialized;
    notifyListeners();
    debug('$runtimeType initialized - deployment mode: ${AppConfig.deploymentMode.name}');
  }

  /// Set the active study from an [invitation] - the app re-loads translations.
  void setStudyInvitation(ActiveParticipationInvitation invitation) {
    // create and save the participant info based on this invitation
    LocalSettings().participant = Participant.fromParticipationInvitation(invitation);

    // Also seeds the CAWS services, so they resolve the study's resources.
    study.study = SmartphoneStudy.fromInvitation(invitation);

    // And then re-initialize the resource manager.
    CarpResourceManager().initialize();

    notifyListeners();

    info('Invitation received - study: ${study.study}');
  }

  /// Deploy the study and start sensing - on failure, reset for retry and rethrow.
  Future<void> configureStudy() async {
    // early out if already configuring or configured
    if (_state == AppState.configuring || isConfigured) {
      return;
    }

    _state = AppState.configuring;
    notifyListeners();

    try {
      // Only once there is a study - this asks for notification permissions.
      await Sensing().initialize(study.deploymentService);
      await study.configure();
    } catch (error) {
      _state = AppState.configurationFailed;
      notifyListeners();
      warning('$runtimeType - Study configuration failed - $error');
      rethrow;
    }

    appViewModel.init(study.controller!);

    messages.start();

    _listenToUserTaskNotifications();

    info('Study configuration done.');

    _state = AppState.configured;
    notifyListeners();

    await study.start();
  }

  /// Open the task page when a task notification is tapped - until [leaveStudy].
  void _listenToUserTaskNotifications() {
    _userTaskNotificationSubscription ??= AppTaskController().userTaskEvents.listen((userTask) {
      if (userTask.state == UserTaskState.notified) {
        userTask.onStart();
        if (userTask.hasWidget) _rootNavigatorKey.currentContext?.push('/task/${userTask.id}');
      }
    });
  }

  /// Stop sensing and wipe the study from the phone - data is not recoverable.
  Future<void> leaveStudy() async {
    info('Leaving study ${study.study}');

    // clear the UI data models, message polling, and notification handling
    appViewModel.clear();
    messages.stop();
    await _userTaskNotificationSubscription?.cancel();
    _userTaskNotificationSubscription = null;

    // stop sensing and remove all deployment info
    await study.remove();

    _state = AppState.initialized;
    notifyListeners();
  }

  /// [leaveStudy] plus permanently deleting all authentication from this phone.
  Future<void> signOutAndLeaveStudy() async {
    await auth.signOut();
    await leaveStudy();
  }

  /// Dispose the entire sensing.
  @override
  void dispose() {
    messages.dispose();
    study.controller?.dispose();
    super.dispose();
  }
}
