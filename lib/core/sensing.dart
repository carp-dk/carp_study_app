/*
 * Copyright 2025 Copenhagen Research Platform (CARP) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_study_app;

/// The sensing layer (singleton): registers sampling packages, data managers,
/// and task factories. Owns no study - the study lifecycle is [StudyService]'s.
class Sensing {
  static final Sensing _instance = Sensing._();

  /// The singleton sensing instance.
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

    // Create and register external data managers.
    // The CARP data manager is needed in both LOCAL and CARP deployments,
    // since a local study protocol may still upload to CAWS.
    DataManagerRegistry().register(CarpDataManagerFactory());

    // register the special-purpose audio user task factory
    AppTaskController().registerUserTaskFactory(AppUserTaskFactory());
  }

  /// Register the available devices and configure the CAMS client manager
  /// with the given [deploymentService].
  Future<void> initialize(DeploymentService deploymentService) async {
    info('Initializing $runtimeType');

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
}
