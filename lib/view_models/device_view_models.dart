part of carp_study_app;

/// The view model for the [DeviceListPage].
class DeviceListPageViewModel extends ViewModel {
  DeviceListPageViewModel({StudyService? studyService}) : _studyService = studyService;

  final StudyService? _studyService;
  StudyService get _study => _studyService ?? bloc.study;

  /// The smartphone (primary) device of this deployment.
  List<DeviceViewModel> get smartphoneDevice =>
      _study.deploymentDevices.where((device) => device.deviceManager is SmartphoneDeviceManager).toList();

  /// The hardware devices (connected devices) of this deployment.
  List<DeviceViewModel> get hardwareDevices => _study.deploymentDevices
      .where(
        (device) => device.deviceManager is HardwareDeviceManager && device.deviceManager is! SmartphoneDeviceManager,
      )
      .toList();

  /// The online services of this deployment.
  List<DeviceViewModel> get onlineServices =>
      _study.deploymentDevices.where((device) => device.deviceManager is ServiceManager).toList();

  /// The Health service of this deployment, if any.
  DeviceViewModel? get healthService =>
      onlineServices.where((device) => device.type == HealthService.DEVICE_TYPE).firstOrNull;
}

/// The view model for each device - [DeviceManager].
///
/// Note that the [deviceManager] can represent both a hardware device and
/// an online service.
class DeviceViewModel extends ViewModel {
  DeviceManager deviceManager;
  DeviceViewModel(this.deviceManager) : super();

  StreamSubscription<DeviceStatus>? _statusSub;

  // Bridge the device manager's status stream into ChangeNotifier
  // notifications, so widgets listening to this view model rebuild when the
  // device connects or disconnects. Subscribed on first listener and cancelled
  // on the last, so the ephemeral instances from `deploymentDevices` don't leak.
  @override
  void addListener(VoidCallback listener) {
    _statusSub ??= deviceManager.statusEvents.listen((_) => notifyListeners());
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _statusSub?.cancel();
      _statusSub = null;
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  /// The type of this device.
  String? get type => deviceManager.deviceType;

  /// A printer-friendly name for this [type] of device.
  String get typeName => _deviceTypeName[type!] ?? 'pages.devices.type.unknown.name';

  /// The status of this device.
  DeviceStatus get status => deviceManager.status;
  set status(DeviceStatus status) => deviceManager.status = status;

  /// Stream of [DeviceStatus] events
  Stream<DeviceStatus> get statusEvents => deviceManager.statusEvents;

  /// The device id
  String get id => deviceManager.displayName ?? '';

  /// A printer-friendly name for this device.
  String get name {
    if (deviceManager is BLEDeviceManager) {
      return (deviceManager as BLEDeviceManager).bleName ?? '';
    } else if (deviceManager is PolarDeviceManager) {
      return (deviceManager as PolarDeviceManager).displayName ?? '';
    } else {
      return id;
    }
  }

  /// A printer-friendly description of this device.
  String get description => '${_deviceTypeDescription[type!]} - ${status.name}\n$batteryLevel% battery remaining.';

  /// The battery level of this device.
  ///
  /// Only relevant if this device is a [HardwareDeviceManager].
  /// Returns null if not a hardware device.
  int? get batteryLevel =>
      (deviceManager is HardwareDeviceManager) ? (deviceManager as HardwareDeviceManager).batteryLevel : null;

  /// The stream of battery level events.
  ///
  /// Only relevant if this device is a [HardwareDeviceManager].
  /// Returns an empty stream if not a hardware device.
  Stream<int> get batteryEvents => deviceManager is HardwareDeviceManager
      ? (deviceManager as HardwareDeviceManager).batteryEvents
      : const Stream.empty();

  /// The icon for this type of device.
  Icon? get icon => _deviceTypeIcon[type!];

  /// The icon or string for the status of this hardware device.
  dynamic get getDeviceStatusIcon => _deviceStatusIcon[status];

  /// The icon or string for the status of service.
  dynamic get getServiceStatusIcon => _serviceStatusIcon[status];

  /// The name for the status of device.
  String? get statusText => _deviceStatusText[status];

  /// Instructions to the user on how to connect to this type of device.
  String? get connectionInstructions => _deviceConnectionInstructions[type!];

  String? get connectionInstructionsImage => _deviceConnectionInstructionsImage[type!];

  PolarDeviceType get polarDeviceType {
    if (deviceManager is PolarDeviceManager) {
      return (deviceManager as PolarDeviceManager).polarDeviceType ?? PolarDeviceType.Unknown;
    } else {
      return PolarDeviceType.Unknown;
    }
  }

  MovesenseDeviceType get movesenseDeviceType {
    if (deviceManager is MovesenseDeviceManager) {
      return (deviceManager as MovesenseDeviceManager).movesenseDeviceType;
    } else {
      return MovesenseDeviceType.UNKNOWN;
    }
  }

  /// Display information about this phone.
  Map<String, String?> get phoneInfo => {
    'name': '${DeviceInfoService().deviceID}',
    'model': '${DeviceInfoService().deviceModel} (${DeviceInfoService().deviceManufacturer?.toUpperCase()})',
    'version': 'SDK ${DeviceInfoService().sdk}',
  };

  /// Map a selected device to the device in the protocol and connect to it.
  void connectToDevice(BluetoothDevice selectedDevice) {
    if (deviceManager is BLEDeviceManager) {
      (deviceManager as BLEDeviceManager).bleAddress = selectedDevice.remoteId.str;
      (deviceManager as BLEDeviceManager).bleName = selectedDevice.platformName;
    }

    deviceManager.connect();
  }

  /// Disconnect from the currently connected device
  Future<void> disconnectFromDevice() async {
    try {
      await deviceManager.disconnect();

      // Erase BLE information so the user can connect to another device, if needed.
      if (deviceManager is BLEDeviceManager) {
        (deviceManager as BLEDeviceManager).bleAddress = '';
        (deviceManager as BLEDeviceManager).bleName = '';
      }
    } catch (error) {
      warning("$runtimeType - Error disconnecting to device '${deviceManager.displayName}' - $error.");
    }
  }
}

const Map<String, String> _deviceTypeName = {
  Smartphone.DEVICE_TYPE: "pages.devices.type.smartphone.name",
  WeatherService.DEVICE_TYPE: "pages.devices.type.weather.name",
  AirQualityService.DEVICE_TYPE: "pages.devices.type.air_quality.name",
  LocationService.DEVICE_TYPE: "pages.devices.type.location.name",
  PolarDevice.DEVICE_TYPE: "pages.devices.type.polar.name",
  MovesenseDevice.DEVICE_TYPE: "pages.devices.type.movesense.name",
  HealthService.DEVICE_TYPE: "pages.devices.type.health.name",
};

const Map<String, String> _deviceTypeDescription = {
  Smartphone.DEVICE_TYPE: "pages.devices.type.smartphone.description",
  WeatherService.DEVICE_TYPE: "pages.devices.type.weather.description",
  AirQualityService.DEVICE_TYPE: "pages.devices.type.air_quality.description",
  LocationService.DEVICE_TYPE: "pages.devices.type.location.description",
  PolarDevice.DEVICE_TYPE: "pages.devices.type.polar.description",
  MovesenseDevice.DEVICE_TYPE: "pages.devices.type.movesense.description",
  HealthService.DEVICE_TYPE: "pages.devices.type.health.description",
};

const Map<String, Icon> _deviceTypeIcon = {
  Smartphone.DEVICE_TYPE: Icon(Icons.phone_android, size: 30, color: CACHET.GREEN_1),
  WeatherService.DEVICE_TYPE: Icon(Icons.wb_cloudy, color: CACHET.BLUE_1),
  AirQualityService.DEVICE_TYPE: Icon(Icons.air, color: CACHET.LIGHT_BLUE),
  LocationService.DEVICE_TYPE: Icon(Icons.location_on, color: CACHET.GREEN),
  PolarDevice.DEVICE_TYPE: Icon(Icons.monitor_heart, size: 30, color: CACHET.RED),
  MovesenseDevice.DEVICE_TYPE: Icon(Icons.circle, size: 30, color: CACHET.GREY_1),
  HealthService.DEVICE_TYPE: Icon(Icons.favorite_rounded, size: 30, color: CACHET.RED_1),
};

const Map<DeviceStatus, dynamic> _deviceStatusIcon = {
  DeviceStatus.configured: "pages.devices.status.action.connect",
  DeviceStatus.connecting: Icon(Icons.bluetooth_searching_rounded, color: CACHET.DARK_BLUE, size: 30),
  DeviceStatus.connected: Icon(Icons.bluetooth_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.disconnected: "pages.devices.status.action.connect",
  DeviceStatus.paired: "pages.devices.status.action.connect",
  DeviceStatus.unknown: Icon(Icons.error_outline, color: CACHET.RED_1, size: 30),
};

const Map<DeviceStatus, dynamic> _serviceStatusIcon = {
  DeviceStatus.configured: "pages.devices.status.action.connect",
  DeviceStatus.connecting: Icon(Icons.sensors_off_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.connected: Icon(Icons.sensors_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.disconnected: "pages.devices.status.action.connect",
  DeviceStatus.paired: "pages.devices.status.action.connect",
  DeviceStatus.unknown: Icon(Icons.error_outline, color: CACHET.RED_1, size: 30),
};

const Map<DeviceStatus, String> _deviceStatusText = {
  DeviceStatus.connecting: "pages.devices.status.connecting",
  DeviceStatus.connected: "pages.devices.status.connected",
  DeviceStatus.disconnected: "pages.devices.status.disconnected",
  DeviceStatus.paired: "pages.devices.status.paired",
  DeviceStatus.configured: "pages.devices.status.initialized",
  DeviceStatus.unknown: "pages.devices.status.unknown",
};

const Map<String, String> _deviceConnectionInstructions = {
  Smartphone.DEVICE_TYPE: "pages.devices.type.smartphone.instructions",
  PolarDevice.DEVICE_TYPE: "pages.devices.type.polar.instructions",
  MovesenseDevice.DEVICE_TYPE: "pages.devices.type.movesense.instructions",
};

const Map<String, String> _deviceConnectionInstructionsImage = {
  Smartphone.DEVICE_TYPE: "assets/icons/connection_done.png",
  PolarDevice.DEVICE_TYPE: "assets/instructions/polar_instructions.png",
  MovesenseDevice.DEVICE_TYPE: "assets/instructions/movesense_instructions.png",
};
