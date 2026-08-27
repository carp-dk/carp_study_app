part of carp_study_app;

/// The state of the [AppBloc], ordered by progress - the `is...` getters
/// compare by index, so a state implies everything before it.
enum AppState {
  /// The BLoC is created but not ready for use.
  created,

  /// The BLoC is initialized via the [initialized] method.
  initialized,

  /// The last study configuration attempt failed. Recover by calling
  /// [AppBloc.tryConfigureStudy] again.
  configurationFailed,

  /// The BLoC is in the process of being configured with a study.
  configuring,

  /// The BLoC is configured with a study and ready to use.
  configured,
}

/// The coordinator for the entire app - the state machine, the focused
/// services, and orchestration spanning them. Singleton, via the global `bloc`.
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
      // Configure the CAWS backend if not in local deployment mode. This is
      // offline-safe (it only configures the CAWS services locally; only
      // authentication/token refresh hit the network), and must run so the
      // deployment service is configured before Sensing().initialize uses it.
      await auth.initialize();
    } else {
      // Deploy the local protocol if running in local mode
      await study.deployLocalProtocol();
    }
    await Sensing().initialize(study.deploymentService);

    _state = AppState.initialized;
    notifyListeners();
    debug('$runtimeType initialized - deployment mode: ${AppConfig.deploymentMode.name}');
  }

  /// Set the active study in the app based on an [invitation].
  ///
  /// The study translations are re-loaded by the app, which listens for the
  /// study change.
  void setStudyInvitation(ActiveParticipationInvitation invitation) {
    // create and save the participant info based on this invitation
    LocalSettings().participant = Participant.fromParticipationInvitation(invitation);

    // save the study; this also seeds the CAWS backend services with it
    // in order to access the correct resources (like translations etc.).
    study.study = SmartphoneStudy.fromInvitation(invitation);

    // And then re-initialize the resource manager.
    CarpResourceManager().initialize();

    notifyListeners();

    info('Invitation received - study: ${study.study}');
  }

  /// Deploy the study, set up messaging and pages, and start sensing.
  /// On failure the state is reset for retry and the error rethrown.
  Future<void> configureStudy() async {
    // early out if already configuring or configured
    if (_state == AppState.configuring || isConfigured) {
      return;
    }

    _state = AppState.configuring;
    notifyListeners();

    try {
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

  /// Open the task page when the user taps a user-task notification from
  /// the OS. The subscription is created once and cancelled in [leaveStudy].
  void _listenToUserTaskNotifications() {
    _userTaskNotificationSubscription ??= AppTaskController().userTaskEvents.listen((userTask) {
      if (userTask.state == UserTaskState.notified) {
        userTask.onStart();
        if (userTask.hasWidget) _rootNavigatorKey.currentContext?.push('/task/${userTask.id}');
      }
    });
  }

  /// Leave the study: stop sensing, wipe study info and consent from the
  /// phone, and return to invitation selection. Local data is not recoverable.
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

  /// Sign user out and leave the study.
  ///
  /// This entails everything from the [leaveStudy] method plus permanently
  /// deleting all user authentication information from this phone, including
  /// the authentication and refresh tokens.
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
