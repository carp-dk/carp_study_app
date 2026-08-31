/*
 * Copyright 2025 Copenhagen Research Platform (CARP) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_study_app;

/// Registers sampling packages, data managers and task factories. Owns no study.
class Sensing {
  static final Sensing _instance = Sensing._();

  /// The singleton sensing instance.
  factory Sensing() => _instance;

  Sensing._() {
    // create and register external sampling packages
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    //SamplingPackageRegistry.register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    SamplingPackageRegistry().register(SurveySamplingPackage());
    SamplingPackageRegistry().register(HealthSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(MovesenseSamplingPackage());

    // Needed in LOCAL too - a local protocol may still upload to CAWS.
    DataManagerRegistry().register(CarpDataManagerFactory());

    // register the special-purpose audio user task factory
    AppTaskController().registerUserTaskFactory(AppUserTaskFactory());
  }

  /// Register the devices and configure the client manager with [deploymentService].
  Future<void> initialize(DeploymentService deploymentService) async {
    // The client manager is a singleton and cannot be reconfigured on retry.
    if (SmartPhoneClientManager().isConfigured) return;

    info('Initializing $runtimeType');

    // Set up the devices available on this phone
    DeviceController().registerAllAvailableDevices();

    // Create and configure a client manager for this phone
    await SmartPhoneClientManager().configure(
      deploymentService: deploymentService,
      dataCollectorFactory: DeviceController(),

      // Need to ask for permissions all at once on Android.
      askForPermissions: Platform.isAndroid ? true : false,

      // Only resumed - the user connects to it themselves the first time.
      enableBackgroundMode: false,
    );

    // Resumes background sensing if the user already connected to it.
    await BackgroundSensingService().refresh();

    info('$runtimeType initialized');
  }
}
