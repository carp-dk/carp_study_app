part of carp_study_app;

/// Manages the study running on this phone: the study descriptor, its
/// deployment, and the sensing runtime for it.
///
/// This service is the single owner of the active study. The persisted copy
/// in [LocalSettings] and the CAWS service copies are seeded from the [study]
/// setter - do not set them directly.
class StudyService {
  StudyService({ResourceManagerFactory? resources}) : _resources = resources ?? ResourceManagerFactory();

  final ResourceManagerFactory _resources;
  SmartphoneStudyController? _controller;
  StudyDeploymentStatus? _status;

  /// The deployment service used in this app, selected by the deployment mode.
  DeploymentService get deploymentService =>
      AppConfig.deploymentMode == DeploymentMode.local ? SmartphoneDeploymentService() : CarpDeploymentService();

  /// The study running on this phone, typically set based on an invitation.
  /// Returns null if no study has been selected (yet).
  SmartphoneStudy? get study => LocalSettings().study;

  /// Set the active [study], persisting it locally and seeding the CAWS
  /// services with it (in non-local deployments).
  set study(SmartphoneStudy? study) {
    if (study == null) return;
    LocalSettings().study = study;
    if (AppConfig.deploymentMode != DeploymentMode.local) CarpBackend().study = study;
  }

  /// Has a study been selected on this phone (i.e., an invitation accepted)?
  ///
  /// Note that this does NOT imply that the study deployment has succeeded -
  /// see [isDeployed] for that.
  bool get hasStudy => study != null;

  /// Has the study deployment succeeded on this phone, i.e. has the device
  /// deployment been received and validated?
  bool get isDeployed => deployment != null;

  /// The study runtime controller for the current study.
  /// Only available after the study has been added via [configure].
  SmartphoneStudyController? get controller => _controller;

  /// The deployment running on this phone.
  /// Returns null if the study has not (yet) been deployed.
  SmartphoneDeployment? get deployment => _controller?.deployment;

  /// When was this study deployed on this phone.
  DateTime? get studyStartTimestamp => deployment?.deployed;

  Set<ExpectedParticipantData?> get expectedParticipantData => deployment?.expectedParticipantData ?? {};

  /// Refresh and return the status of the current study deployment from the
  /// deployment service. Returns null if no study has been deployed.
  Future<StudyDeploymentStatus?> refreshDeploymentStatus() async {
    final id = study?.studyDeploymentId;
    return id != null ? _status = await deploymentService.getStudyDeploymentStatus(id) : null;
  }

  /// The last known status of the study deployment, without contacting the
  /// deployment service. Use [refreshDeploymentStatus] to refresh it.
  StudyDeploymentStatus? get cachedDeploymentStatus => _status;

  /// Initialize sensing and deploy the [study] on this phone.
  ///
  /// Throws if no study is set, or if deployment does not succeed - in which
  /// case it is safe to call this method again (e.g., once back online).
  Future<void> configure() async {
    if (study == null) throw StateError('No study set - cannot configure a study deployment.');
    logApp('StudyService.configure() - deploymentId=${study!.studyDeploymentId}, deviceRole=${study!.deviceRoleName}');

    await Sensing().initialize(deploymentService);
    final status = await addStudy(study!);

    logApp('StudyService.configure() - addStudy returned status=$status, isDeployed=$isDeployed');
    if (!isDeployed) throw StateError('Study deployment did not succeed - status: $status.');
  }

  /// Add the [study] to the client manager and deploy it.
  Future<StudyStatus?> addStudy(SmartphoneStudy study) async {
    assert(
      SmartPhoneClientManager().isConfigured,
      'The client manager is not yet configured. Call Sensing().initialize() before adding a study.',
    );

    await SmartPhoneClientManager().addStudy(study);
    return await tryDeployment();
  }

  /// Try to deploy the current study.
  ///
  /// Note that if the study has already been deployed on this phone it has
  /// been cached locally and the local version will be used pr. default.
  /// If not deployed before the study deployment will be fetched from the
  /// deployment service. Returns null if no study has been selected yet.
  Future<StudyStatus?> tryDeployment() async {
    if (study == null) return null;

    final status = await SmartPhoneClientManager().tryDeployment(study!.studyDeploymentId, study!.deviceRoleName);
    _controller = SmartPhoneClientManager().getStudyController(study!);
    translateProtocol();

    info('$runtimeType - Study added, deployment id: ${study!.studyDeploymentId}');
    return status;
  }

  /// Is sensing running, i.e. has the study executor been resumed?
  bool get isRunning => (_controller != null) && _controller!.executor.state == ExecutorState.Resumed;

  /// Start sensing, if the study is deployed and not permanently stopped.
  Future<void> start() async {
    final controller = _controller;
    if (controller == null || !isDeployed || controller.study.status == StudyStatus.Stopped) {
      warning(
        '$runtimeType - Cannot start sensing - the study is not deployed '
        '(status: ${controller?.study.status}).',
      );
      return;
    }

    // The controller initializes its executor asynchronously after the device
    // deployment is received, and resume() before that is silently ignored -
    // so wait for the executor to be ready.
    const retryDelay = Duration(milliseconds: 100);
    var waited = Duration.zero;
    while (controller.executor.state == ExecutorState.Created && waited < const Duration(seconds: 30)) {
      await Future<void>.delayed(retryDelay);
      waited += retryDelay;
    }
    if (controller.executor.state == ExecutorState.Created) {
      warning('$runtimeType - Cannot start sensing - the study executor was never initialized.');
      return;
    }

    if (!isRunning) controller.resume();
  }

  /// Add [measurement] to the stream of collected measurements.
  void addMeasurement(Measurement measurement) => _controller?.executor.addMeasurement(measurement);

  /// The list of all devices used in the current deployment.
  ///
  /// Note that not all available devices on this phone may be used in the
  /// current deployment.
  Iterable<DeviceViewModel> get deploymentDevices => deployment == null
      ? []
      : SmartPhoneClientManager().deviceController.devices.values
            .where((manager) => deployment!.devices.any((device) => device.type == manager.deviceType))
            .map((manager) => DeviceViewModel(manager));

  /// Does this [deployment] have any measures (besides app tasks)?
  bool hasMeasures() => (deployment == null)
      ? false
      : (deployment!.measures.any(
          (measure) =>
              (measure.type != AppTask.VIDEO_TYPE &&
              measure.type != AppTask.IMAGE_TYPE &&
              measure.type != AppTask.AUDIO_TYPE &&
              measure.type != AppTask.SURVEY_TYPE),
        ));

  /// Does this [deployment] have the measure of type [type]?
  bool hasMeasure(String type) => deployment?.measures.any((measure) => measure.type == type) ?? false;

  /// Does this [deployment] have any user tasks?
  bool hasUserTasks() => (deployment == null) ? false : deployment!.tasks.whereType<AppTask>().isNotEmpty;

  /// Translate the title and description of all [AppTask]s in the current
  /// deployment using [AppConfig.localization].
  void translateProtocol([RPLocalizations? localization]) {
    AppConfig.localization ??= localization;

    // Fast out if no localization
    if (AppConfig.localization == null) return;

    // Fast out, if not deployed or no protocol.
    if (!(study?.isDeployed ?? false) || deployment == null) return;

    for (var task in deployment!.tasks) {
      if (task is AppTask) {
        task.title = AppConfig.localization!.translate(task.title);
        task.description = AppConfig.localization!.translate(task.description);
      }
    }

    info("$runtimeType - Study protocol translated to locale '${AppConfig.localization!.locale}'");
  }

  /// Get the participant data for the current deployment.
  Future<List<ParticipantData>> getParticipantDataListFromDeployment() async => (deployment == null)
      ? []
      : await _resources.participationService.getParticipantDataList([deployment!.studyDeploymentId]);

  /// Set the participant [data] for the current study.
  void setParticipantData(Map<String, Data> data) =>
      _resources.participationService.setParticipantData(study!.studyDeploymentId, data, study!.participantRoleName);

  /// Deploy the local protocol if running in local mode.
  ///
  /// We can run the app in local mode to debug a local protocol stored in
  /// assets/carp/resources/protocol.json
  ///
  /// This method will deploy the protocol in the local SmartphoneDeploymentService
  /// which later will be used for deployment. See [deploymentService].
  Future<void> deployLocalProtocol() async {
    if (AppConfig.deploymentMode != DeploymentMode.local) return;

    if (hasStudy) {
      info(
        'Running in local deployment mode. Note that the local protocol has '
        'already been deployed and the cached version will be loaded and used. '
        'If you want to reload a modified protocol, delete the app with the '
        'cached protocol from the phone before running it.',
      );
    } else {
      debug('$runtimeType - deploying local protocol');

      // Get the protocol from the local study protocol manager.
      // Note that the study id is not used since it always returns the same protocol.
      var protocol = await LocalResourceManager().getStudyProtocol('');

      // Deploy this protocol using the on-phone deployment service.
      final status = await SmartphoneDeploymentService().createStudyDeployment(protocol!);

      // The primary device (the smartphone) is found in the device status list.
      final primaryDeviceRoleName = status.deviceStatusList
          .firstWhere((deviceStatus) => deviceStatus.device is PrimaryDeviceConfiguration)
          .device
          .roleName;

      // Save the participant and study on the phone for use across app restart.
      LocalSettings().participant = Participant(
        studyDeploymentId: status.studyDeploymentId,
        deviceRoleName: primaryDeviceRoleName,
      );
      study = SmartphoneStudy(studyDeploymentId: status.studyDeploymentId, deviceRoleName: primaryDeviceRoleName);
    }
  }

  /// Stop sensing and remove all study deployment information from this phone.
  Future<void> remove() async {
    if (study != null) {
      await SmartPhoneClientManager().removeStudy(study!.studyDeploymentId, study!.deviceRoleName);
    }
    _controller = null;
    _status = null;
    await LocalSettings().eraseStudyDeployment();
  }
}
