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

/// How to deploy a study.
enum DeploymentMode {
  /// Use a local study protocol & deployment and store data locally on the phone.
  local,

  /// Use the CAWS production server to get the study deployment and store data.
  production,

  /// Use the CAWS test server to get the study deployment and store data.
  test,

  /// Use the CAWS development server to get the study deployment and store data.
  dev,
}

/// The main Business Logic Component (BLoC) for the entire app.
///
/// Works as a singleton and can always be accessed via the global `bloc`
/// variable.
///
/// Works as a [ChangeNotifier] and will notify its listeners on important
/// changes. Is also stateful and has a [state] and state changes are propagated
/// through the [stateStream].
///
/// The BLoC is configured using two environment variables:
///
///  * `deployment-mode` set the [DeploymentMode].
///  * `debug-level` set the [DebugLevel].
///
/// In Flutter these environment variables are set by specifying the `--dart-define`
/// option in `flutter run`. For example:
///
///  `flutter run --dart-define=deployment-mode=local,debug-level=info`
class StudyAppBLoC extends ChangeNotifier {
  StudyAppState _state = StudyAppState.created;
  final CarpBackend _backend = CarpBackend();
  final CarpStudyAppViewModel _appViewModel = CarpStudyAppViewModel();
  List<Message> _messages = [];
  final StreamController<int> _messageStreamController = StreamController.broadcast();

  /// The state of this BloC.
  StudyAppState get state => _state;

  bool get isInitialized => _state.index >= StudyAppState.initialized.index;
  bool get isConfiguring => _state.index >= StudyAppState.configuring.index;
  bool get isConfigured => _state.index >= StudyAppState.configured.index;

  /// Debug level for the app and CAMS.
  DebugLevel debugLevel = DebugLevel.info;

  /// What kind of deployment are we running?
  DeploymentMode deploymentMode = DeploymentMode.production;

  /// The localization (language)) of this app.
  RPLocalizations? localization;

  /// The list of currently available messages.
  List<Message> get messages => _messages;

  /// A stream of event when the list of [messages] is updated.
  /// The data send on the stream is the number of available messages.
  Stream<int> get messageStream => _messageStreamController.stream;

  // ScaffoldMessenger for showing snack bars
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;
  State? get scaffoldMessengerState => scaffoldKey.currentState;

  /// Create the BLoC for the app.
  StudyAppBLoC() : super() {
    const dep = String.fromEnvironment('deployment-mode', defaultValue: 'production');
    deploymentMode = DeploymentMode.values.where((element) => element.name == dep).first;

    const deb = String.fromEnvironment('debug-level', defaultValue: 'info');
    debugLevel = DebugLevel.values.where((element) => element.name == deb).first;

    info('$runtimeType created. '
        'DeploymentMode: ${deploymentMode.name}, '
        'DebugLevel: ${debugLevel.name}');
  }

  LocalizationManager get localizationManager =>
      (deploymentMode == DeploymentMode.local ? LocalResourceManager() : CarpResourceManager()) as LocalizationManager;

  LocalizationLoader get localizationLoader {
    debug('$runtimeType - using localizationManager: $localizationManager');
    return ResourceLocalizationLoader(localizationManager);
  }

  MessageManager get messageManager =>
      (deploymentMode == DeploymentMode.local ? LocalResourceManager() : CarpResourceManager()) as MessageManager;

  InformedConsentManager get informedConsentManager =>
      (bloc.deploymentMode == DeploymentMode.local ? LocalResourceManager() : CarpResourceManager())
          as InformedConsentManager;

  ParticipationService get participationService =>
      (bloc.deploymentMode == DeploymentMode.local ? LocalParticipationService() : CarpParticipationService());

  CarpBackend get backend => _backend;

  /// The study running on this phone.
  /// Typical set based on an invitation.
  /// `null` if no deployment have been specified.
  SmartphoneStudy? get study => LocalSettings().study;
  set study(SmartphoneStudy? study) => LocalSettings().study = study;

  /// Has a study been deployed on this phone?
  bool get hasStudyBeenDeployed => study != null;

  /// The deployment running on this phone.
  SmartphoneDeployment? get deployment => Sensing().controller?.deployment;

  Set<ExpectedParticipantData?> get expectedParticipantData => deployment?.expectedParticipantData ?? {};

  /// Get the status for the current study deployment.
  /// Returns null if the study is not yet deployed on this phone.
  Future<StudyDeploymentStatus?> get studyDeploymentStatus async => await Sensing().getStudyDeploymentStatus();

  /// When was this study deployed on this phone.
  DateTime? get studyStartTimestamp => deployment?.deployed;

  /// The overall data model for this app
  CarpStudyAppViewModel get appViewModel => _appViewModel;

  final appCheck = AppCheck();

  List<AppInfo>? installedApps;

  /// Initialize this BLOC. Called before being used for anything.
  Future<void> initialize() async {
    if (isInitialized) return;

    Settings().debugLevel = debugLevel;
    await Settings().init();
    CarpResourceManager().initialize();

    Sensing();

    // Initialize and use the CAWS backend if not in local deployment mode
    if (deploymentMode != DeploymentMode.local) {
      if (await checkConnectivity()) {
        await backend.initialize();
      }
    }

    // Deploy the local protocol if running in local mode
    if (deploymentMode == DeploymentMode.local) {
      await deployLocalProtocol();
    }

    _state = StudyAppState.initialized;
    notifyListeners();
    debug('$runtimeType initialized - deployment mode: ${deploymentMode.name}');
  }

  /// Is the phone connected to the internet either via wifi or mobile network?
  Future<bool> checkConnectivity() async {
    final List<ConnectivityResult> results = await (Connectivity().checkConnectivity());

    return results.any((element) => element == ConnectivityResult.mobile || element == ConnectivityResult.wifi);
  }

  /// Check if the Health database is installed on this phone.
  ///
  /// Always returns true on iOS, since Health is part of the OS and hence always installed.
  /// On Android, returns true if Google Health Connect is installed, false otherwise.
  Future<bool> isHealthInstalled() async {
    if (Platform.isIOS) return true;

    try {
      final apps = await appCheck.getInstalledApps() ?? [];
      return apps.any((app) => app.packageName == LocalSettings.healthConnectPackageName);
    } catch (e) {
      debug("$runtimeType - Error checking Health Connect installation: $e");
      return false;
    }
  }

  Future<bool?> getAppHasUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    AppVersionResult result = await AppVersionUpdate.checkForUpdates(
      playStoreId: packageInfo.packageName,
      appleId: '1569798025',
      country: 'dk',
    );
    return result.canUpdate;
  }

  /// Deploy the local protocol if running in local mode.
  ///
  /// We can run the app in local mode to debug a local protocol stored in
  /// assets/carp/resources/protocol.json
  ///
  /// This method will deploy the protocol in the local SmartphoneDeploymentService
  /// which later will be used for deployment. See [Sensing.deploymentService].
  Future<void> deployLocalProtocol() async {
    if (deploymentMode != DeploymentMode.local) return;

    if (hasStudyBeenDeployed) {
      info('Running in local deployment mode. Note that the local protocol has '
          'already been deployed and the cached version will be loaded and used. '
          'If you want to reload a modified protocol, delete the app with the '
          'cached protocol from the phone before running it.');
    } else {
      debug('$runtimeType - deploying local protocol');

      // Get the protocol from the local study protocol manager.
      // Note that the study id is not used since it always returns the same protocol.
      var protocol = await LocalResourceManager().getStudyProtocol('');

      // Deploy this protocol using the on-phone deployment service.
      final status = await SmartphoneDeploymentService().createStudyDeployment(protocol!);

      // Save the participant and study on the phone for use across app restart.
      var participant = Participant(
        studyDeploymentId: status.studyDeploymentId,
        deviceRoleName: status.primaryDeviceStatus?.device.roleName,
      );
      LocalSettings().participant = participant;

      bloc.study = SmartphoneStudy(
        studyDeploymentId: status.studyDeploymentId,
        deviceRoleName: status.primaryDeviceStatus!.device.roleName,
      );
    }
  }

  /// Set the active study in the app based on an [invitation].
  ///
  /// If a [context] is provided, the translation for this study is re-loaded
  /// and applied in the app.
  void setStudyInvitation(
    ActiveParticipationInvitation invitation,
    BuildContext? context,
  ) {
    // create and save the participant info based on this invitation
    var participant = Participant.fromParticipationInvitation(invitation);
    LocalSettings().participant = participant;

    LocalSettings().study = SmartphoneStudy.fromInvitation(invitation);

    // make sure that the CAWS backend services are configured with the study
    // in order to access the correct resources (like translations etc.).
    backend.study = study!;

    // And the re-initialize the resource manager.
    CarpResourceManager().initialize();

    notifyListeners();

    info('Invitation received - study: $study');

    if (context != null) CarpStudyApp.reloadLocale(context);
  }

  /// This methods is used to configure the [study] deployment.
  ///
  /// This includes:
  ///  * initialize sensing
  ///  * adding the CAMS study
  ///  * setting up messaging
  ///  * initializing the data visualization pages
  Future<void> configureStudy() async {
    // early out if already configured
    if (isConfiguring) return;

    _state = StudyAppState.configuring;

    // set up and initialize sensing
    await Sensing().initialize();

    // make sure that the CAWS backend services are configured with the study
    backend.study = study!;

    // add the study and configure sensing
    await Sensing().addStudy();

    // initialize the UI data models
    appViewModel.init(Sensing().controller!);

    // set up the messaging part and get the initial list of messages
    messageManager.initialize();
    refreshMessages();

    // refresh the list of messages on a regular basis
    Timer.periodic(const Duration(minutes: 30), (_) => refreshMessages());

    info('Study configuration done.');
    notifyListeners();
    _state = StudyAppState.configured;
  }

  Future<List<ParticipantData>> getParticipantDataListFromDeployment() async =>
      (deployment == null) ? [] : await participationService.getParticipantDataList([deployment!.studyDeploymentId]);

  /// Set the participant data for this study.
  void setParticipantData(
    String studyDeploymentId,
    Map<String, Data> data, [
    String? inputByParticipantRole,
  ]) =>
      participationService.setParticipantData(
        studyDeploymentId,
        data,
        inputByParticipantRole,
      );

  /// Does this app use location permissions?
  bool get usingLocationPermissions => true;

  /// Get the informed consent for this study.
  Future<RPOrderedTask?> getInformedConsent({bool refresh = false}) =>
      informedConsentManager.getInformedConsent(refresh: refresh);

  /// Has the informed consent been accepted by the user?
  bool get hasInformedConsentBeenAccepted =>
      backend.getInformedConsentByRole(study!.studyDeploymentId, study!.participantRoleName) != null;

  set hasInformedConsentBeenAccepted(bool accepted) {
    var participant = LocalSettings().participant;
    participant?.hasInformedConsentBeenAccepted = true;
    LocalSettings().participant = participant;
  }

  /// Mark the informed consent as accepted by the user based on the
  /// [informedConsentResult].
  ///
  /// This entails that it has been shown to the user and accepted by the user.
  /// Will upload it to CAWS (if not running in local deployment mode).
  Future<void> informedConsentHasBeenAccepted(
    RPTaskResult informedConsentResult,
  ) async {
    info('Informed consent has been accepted by user.');
    hasInformedConsentBeenAccepted = true;

    if (deploymentMode != DeploymentMode.local) {
      await backend.uploadInformedConsent(informedConsentResult);
    }
  }

  /// Refresh the list of messages (news, announcements, articles) to be shown in
  /// the Study Page of the app.
  Future<void> refreshMessages() async {
    try {
      _messages.clear();
      _messages = await messageManager.getMessages();
      _messages.sort((m1, m2) => m2.timestamp.compareTo(m1.timestamp));
      info('Message list refreshed - count: ${_messages.length}');
    } catch (error) {
      warning('Error getting messages - $error');
    }
    _messageStreamController.add(_messages.length);
  }

  /// The signed in user. Returns null if no user is signed in.
  CarpUser? get user => backend.user;

  /// The username of the user running this study.
  /// Returns an empty string if no user logged in.
  String? get username => user!.username;

  /// The name used for friendly greeting.
  /// Returns an empty string if no user logged in.
  String? get friendlyUsername => (user != null) ? user!.firstName : '';

  /// Does this [deployment] have any measures?
  bool hasMeasures() => (deployment == null)
      ? false
      : (deployment!.measures.any((measure) => (measure.type != SurveyUserTask.VIDEO_TYPE &&
          measure.type != SurveyUserTask.IMAGE_TYPE &&
          measure.type != SurveyUserTask.AUDIO_TYPE &&
          measure.type != SurveyUserTask.SURVEY_TYPE)));

  /// Does this [deployment] have the measure of type [type]?
  bool hasMeasure(String type) {
    if (deployment == null) return false;

    try {
      deployment?.measures.firstWhere((measure) => measure.type == type);
    } catch (_) {
      return false;
    }

    return true;
  }

  /// Does this [deployment] have any user tasks?
  bool hasUserTasks() => (deployment == null) ? false : deployment!.tasks.whereType<AppTask>().isNotEmpty;

  /// Does this [deployment] have any connected devices?
  bool hasDevices() => (deployment == null) ? false : deployment!.connectedDevices.isNotEmpty;

  /// Is sensing running, i.e. has the study executor been resumed?
  bool get isRunning => Sensing().isRunning;

  /// the list of running - i.e. used - probes in this study.
  List<Probe> get runningProbes => (Sensing().controller != null) ? Sensing().controller!.executor.probes : [];

  DeploymentService get deploymentService => Sensing().deploymentService;

  /// The list of all devices in this deployment.
  Iterable<DeviceViewModel> get deploymentDevices =>
      Sensing().deploymentDevices.map((device) => DeviceViewModel(device));

  /// Start sensing.
  Future<void> start() async {
    assert(Sensing().controller != null, 'No Study Controller - the study has not been deployed.');
    if (!Sensing().isRunning) Sensing().controller?.start();
  }

  /// Stop sensing.
  void stop() => Sensing().controller?.stop();

  /// Dispose the entire sensing.
  @override
  void dispose() {
    super.dispose();
    Sensing().controller?.dispose();
  }

  /// Add [measurement] to the stream of collected measurements.
  void addMeasurement(Measurement measurement) => Sensing().controller?.executor.addMeasurement(measurement);

  /// Add [error] to the stream of measurements.
  void addError(Object error, [StackTrace? stacktrace]) => Sensing().controller?.executor.addError(error, stacktrace);

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
    info('Leaving study $study');

    // clear the UI data models
    appViewModel.clear();

    // stop sensing and remove all deployment info
    await Sensing().removeStudy();
    await LocalSettings().eraseStudyDeployment();

    _state = StudyAppState.initialized;
    notifyListeners();
  }

  /// Sign user out and leave the study.
  ///
  /// This entails everything from the [leaveStudy] method plus permanently
  /// deleting all user authentication information from this phone, including
  /// the authentication and refresh tokens.
  Future<void> signOutAndLeaveStudy() async {
    await backend.signOut();
    await leaveStudy();
  }
}
