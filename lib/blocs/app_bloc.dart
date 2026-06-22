part of carp_study_app;

/// The state of the [StudyAppBLoC].
enum StudyAppState {
  /// The BLoC is created but not ready for use.
  created,

  /// The BLoC is initialized via the [initialized] method.
  initialized,

  /// The BLoC is in the process of being configured with a study.
  configuring,

  /// The BLoC is configured with a study and ready to use.
  configured,
}

/// The coordinator for the entire app.
///
/// Works as a singleton and can always be accessed via the global `bloc`
/// variable.
///
/// Holds the app state machine and the focused services doing the actual
/// work ([config], [auth], [study], [messages], [consent], [system],
/// [resources]). Orchestration that spans several services - like
/// [configureStudy] and [leaveStudy] - lives here.
///
/// Works as a [ChangeNotifier] and will notify its listeners (incl. the
/// router) on important changes.
class StudyAppBLoC extends ChangeNotifier {
  StudyAppState _state = StudyAppState.created;
  final CarpStudyAppViewModel _appViewModel = CarpStudyAppViewModel();
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
  StudyAppState get state => _state;

  bool get isInitialized => _state.index >= StudyAppState.initialized.index;
  bool get isConfiguring => _state.index >= StudyAppState.configuring.index;
  bool get isConfigured => _state.index >= StudyAppState.configured.index;

  /// The overall data model for this app
  CarpStudyAppViewModel get appViewModel => _appViewModel;

  // ScaffoldMessenger for showing snack bars
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;

  /// Create the BLoC for the app.
  StudyAppBLoC() : super() {
    info(
      '$runtimeType created. '
      'DeploymentMode: ${AppConfig.deploymentMode.name}, '
      'DebugLevel: ${AppConfig.debugLevel.name}',
    );

    // The coordinator is the sole router-notifier - forward service changes.
    // Once consent is given, the study can be configured and started.
    consent.addListener(_onConsentChanged);
  }

  void _onConsentChanged() {
    logAppState('StudyAppBLoC._onConsentChanged() - consent.isAccepted=${consent.isAccepted}');
    notifyListeners();
    if (consent.isAccepted == true) unawaited(tryConfigureStudy());
  }

  /// Run [configureStudy], surfacing a failure to the user instead of
  /// throwing. Used by the setup flow and retry affordances, where no
  /// caller can handle the error.
  Future<void> tryConfigureStudy() async {
    logAppState('StudyAppBLoC.tryConfigureStudy() START');
    try {
      await configureStudy();
    } catch (error) {
      logAppState('StudyAppBLoC.tryConfigureStudy() FAILED - $error');
      final context = scaffoldKey.currentContext;
      final locale = context != null ? RPLocalizations.of(context) : null;
      scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(locale?.translate('pages.home.setup_failed') ?? 'Could not set up the study.')),
      );
    }
  }

  /// Initialize this BLOC. Called before being used for anything.
  Future<void> initialize() async {
    if (isInitialized) return;
    logAppState('StudyAppBLoC.initialize() START');

    Settings().debugLevel = AppConfig.debugLevel;
    await Settings().init();

    CarpResourceManager().initialize();

    Sensing();

    if (AppConfig.deploymentMode != DeploymentMode.local) {
      // Initialize and use the CAWS backend if not in local deployment mode
      if (await system.checkConnectivity()) {
        await auth.initialize();
      }
    } else {
      // Deploy the local protocol if running in local mode
      await study.deployLocalProtocol();
    }

    _state = StudyAppState.initialized;
    notifyListeners();
    debug('$runtimeType initialized - deployment mode: ${AppConfig.deploymentMode.name}');

    logAppState('StudyAppBLoC.initialize() DONE');

    // For a returning user, check consent - via [_onConsentChanged] this
    // routes to the consent page or configures and starts the study.
    if (study.hasStudy) {
      logApp('StudyAppBLoC.initialize() - returning user has a persisted study, refreshing consent status');
      unawaited(consent.refreshStatus(study.study));
    }
  }

  /// Set the active study in the app based on an [invitation].
  ///
  /// The study translations are re-loaded by the app, which listens for the
  /// study change.
  void setStudyInvitation(ActiveParticipationInvitation invitation) {
    logApp(
      'StudyAppBLoC.setStudyInvitation() - accepting invitation: '
      'deploymentId=${invitation.studyDeploymentId}, participantId=${invitation.participation.participantId}',
    );

    // create and save the participant info based on this invitation
    LocalSettings().participant = Participant.fromParticipationInvitation(invitation);

    // save the study; this also seeds the CAWS backend services with it
    // in order to access the correct resources (like translations etc.).
    study.study = SmartphoneStudy.fromInvitation(invitation);

    // And then re-initialize the resource manager.
    CarpResourceManager().initialize();

    notifyListeners();

    info('Invitation received - study: ${study.study}');
    logAppState('StudyAppBLoC.setStudyInvitation() DONE - study set, refreshing consent status');

    // Routes to the consent page - or, if this participant has already
    // consented (e.g. on another phone), configures and starts the study.
    unawaited(consent.refreshStatus(study.study));
  }

  /// Configure the study deployment and start sensing.
  ///
  /// This includes:
  ///  * initialize sensing and deploy the study
  ///  * initializing the data visualization pages
  ///  * setting up messaging
  ///  * starting sensing (only if the deployment succeeded)
  ///
  /// If configuration fails (e.g., no network), the state is reset so this
  /// method can be called again, and the error is rethrown for the caller
  /// to surface.
  Future<void> configureStudy() async {
    // early out if already configuring or configured
    if (_state == StudyAppState.configuring || isConfigured) {
      logApp('StudyAppBLoC.configureStudy() - skipped, already ${_state.name}');
      return;
    }
    logAppState('StudyAppBLoC.configureStudy() START');

    final previousState = _state;
    _state = StudyAppState.configuring;

    try {
      await study.configure();
    } catch (error) {
      _state = previousState;
      warning('$runtimeType - Study configuration failed - $error');
      logAppState('StudyAppBLoC.configureStudy() FAILED - study.configure() threw - $error');
      rethrow;
    }

    appViewModel.init(study.controller!);

    messages.start();

    _listenToUserTaskNotifications();

    info('Study configuration done.');

    _state = StudyAppState.configured;
    notifyListeners();
    logAppState('StudyAppBLoC.configureStudy() DONE - now starting sensing');

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

  /// Leave the study deployed on this phone.
  ///
  /// This entails
  ///  * stopping sensing
  ///  * removing the study info from the phone
  ///  * resetting the informed consent flow
  ///  * returning the user to select an invitation for another study
  ///
  /// Note that study deployment information and data is removed from the
  /// phone. If the same deployment is re-deployed on the phone, data from the
  /// previous deployment will NOT be available.
  Future<void> leaveStudy() async {
    info('Leaving study ${study.study}');

    // clear the UI data models, message polling, and notification handling
    appViewModel.clear();
    messages.stop();
    await _userTaskNotificationSubscription?.cancel();
    _userTaskNotificationSubscription = null;
    consent.reset();

    // stop sensing and remove all deployment info
    await study.remove();

    _state = StudyAppState.initialized;
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
