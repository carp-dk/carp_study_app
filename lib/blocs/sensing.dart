/*
 * Copyright 2025 Copenhagen Research Platform (CARP) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_study_app;

/// This class implements the sensing layer.
///
/// Call [initialize] to setup a deployment using a CARP deployment.
/// Once initialized, use the [addStudy] method to add the study to this runtime.
/// The runtime [controller] can be used to control the study execution
/// (i.e., start or stop).
///
/// Note that this class is a singleton and only one sensing layer is used.
/// The current assumption at the moment is that this Study App only
/// runs one study at a time, even though CAMS supports that several studies
/// added to the [client].
class Sensing {
  static final Sensing _instance = Sensing._();
  StudyDeploymentStatus? _status;
  SmartphoneStudyController? _controller;
  SmartphoneStudy? _study;

  /// The deployment service used in this app.
  DeploymentService get deploymentService =>
      AppConfig().deploymentMode == DeploymentMode.local ? SmartphoneDeploymentService() : CarpDeploymentService();

  /// The study running on this phone.
  /// Only available after [addStudy] is called.
  SmartphoneStudy? get study => _study;

  /// The deployment running on this phone.
  /// Only available after [addStudy] is called.
  SmartphoneDeployment? get deployment => _controller?.deployment;

  /// The latest status of the study deployment.
  StudyDeploymentStatus? get status => _controller?.deploymentStatus;

  /// The role name of this device in the deployed study.
  String? get deviceRoleName => _study?.deviceRoleName;

  /// The study deployment id of the deployment running on this phone.
  String? get studyDeploymentId => _study?.studyDeploymentId;

  /// The study runtime for this deployment.
  SmartphoneStudyController? get controller => _controller;

  /// Is sensing running, i.e. has the study executor been resumed?
  bool get isRunning => (controller != null) && controller!.executor.state == ExecutorState.Resumed;

  /// The list of running - i.e. used - probes in this study.
  List<Probe> get runningProbes => (_controller != null) ? _controller!.executor.probes : [];

  /// The list of all device managers used in the current deployment.
  ///
  /// Note that not all available devices on this phone may be used in the
  /// current deployment. Hence, this method returns the list of device managers
  /// used in the current deployment.
  List<DeviceManager> get deploymentDevices => deployment != null
      ? SmartPhoneClientManager().deviceController.devices.values
            .where((manager) => deployment!.devices.any((element) => element.type == manager.deviceType))
            .toList()
      : [];

  /// The smartphone (primary device) manager.
  SmartphoneDeviceManager get smartphoneDeviceManager =>
      SmartPhoneClientManager().deviceController.smartphoneDeviceManager;

  /// The list of connected devices.
  List<DeviceManager>? get connectedDevices => SmartPhoneClientManager().deviceController.connectedDevices;

  /// The singleton sensing instance
  factory Sensing() => _instance;

  Sensing._() {
    // create and register external sampling packages
    //SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    //SamplingPackageRegistry.register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    SamplingPackageRegistry().register(SurveySamplingPackage());
    SamplingPackageRegistry().register(HealthSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(MovesenseSamplingPackage());

    // CAWS deployments created before CAMS 2.x serialize device types in the
    // old namespace - register the device types under it as well.
    const oldDeviceNamespace = 'dk.cachet.carp.common.application.devices';
    for (final device in <DeviceConfiguration>[
      Smartphone(),
      LocationService(),
      WeatherService(apiKey: ''),
      AirQualityService(apiKey: ''),
      HealthService(),
      PolarDevice(),
      MovesenseDevice(),
    ]) {
      FromJsonFactory().register(device, type: '$oldDeviceNamespace.${device.runtimeType}');
    }

    // Create and register external data managers.
    // The CARP data manager is needed in both LOCAL and CARP deployments,
    // since a local study protocol may still upload to CAWS.
    DataManagerRegistry().register(CarpDataManagerFactory());

    // register the special-purpose audio user task factory
    AppTaskController().registerUserTaskFactory(AppUserTaskFactory());
  }

  /// Initialize and set up sensing.
  Future<void> initialize() async {
    info('Initializing $runtimeType - mode: ${AppConfig().deploymentMode}');

    // Set up the devices available on this phone
    DeviceController().registerAllAvailableDevices();

    // Create and configure a client manager for this phone
    await SmartPhoneClientManager().configure(
      deploymentService: deploymentService,
      dataCollectorFactory: DeviceController(),

      // Need to ask for permissions all at once on Android.
      askForPermissions: Platform.isAndroid ? true : false,
    );

    info('$runtimeType initialized');
  }

  /// Add the [study] to the client manager and deploy it.
  Future<StudyStatus> addStudy(SmartphoneStudy study) async {
    assert(
      SmartPhoneClientManager().isConfigured,
      'The client manager is not yet configured. Call SmartPhoneClientManager().configure() before adding a study.',
    );

    _study = await SmartPhoneClientManager().addStudy(study);

    return await tryDeployment();
  }

  /// Try to deploy the study.
  ///
  /// Note that if the study has already been deployed on this phone it has
  /// been cached locally and the local version will be used pr. default.
  /// If not deployed before the study deployment will be fetched from the
  /// deployment service.
  Future<StudyStatus> tryDeployment() async {
    assert(study != null, 'No study is provided. Cannot deploy w/o a study. Call addStudy() first.');

    StudyStatus status = await SmartPhoneClientManager().tryDeployment(study!.studyDeploymentId, study!.deviceRoleName);

    _controller = SmartPhoneClientManager().getStudyController(_study!);

    translateStudyProtocol();

    info('$runtimeType - Study added, deployment id: $studyDeploymentId');
    return status;
  }

  Future<void> removeStudy() async {
    if (study == null) return;
    await SmartPhoneClientManager().removeStudy(study!.studyDeploymentId, study!.deviceRoleName);
  }

  /// Get the last known status for the current study deployment.
  /// Use [getStudyDeploymentStatus] to refresh the status from CAWS.
  /// Returns null if the study is not yet deployed on this phone.
  StudyDeploymentStatus? get studyDeploymentStatus => _status;

  /// Get the status for the current study deployment.
  /// Returns null if the study is not yet deployed on this phone.
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus() async =>
      studyDeploymentId != null ? _status = await deploymentService.getStudyDeploymentStatus(studyDeploymentId!) : null;

  /// Translate the title and description of all AppTask in the study protocol
  /// of the current master deployment.
  void translateStudyProtocol([RPLocalizations? localization]) {
    final config = AppConfig();
    config.localization ??= localization;

    // Fast out if no localization
    if (config.localization == null) return;

    // Fast out, if not deployed or no protocol.
    if (!(study?.isDeployed ?? false) || controller?.deployment == null) {
      return;
    }

    for (var task in controller!.deployment!.tasks) {
      if (task is AppTask) {
        task.title = config.localization!.translate(task.title);
        task.description = config.localization!.translate(task.description);
      }
    }

    info("$runtimeType - Study protocol translated to locale '${config.localization!.locale}'");
  }
}
