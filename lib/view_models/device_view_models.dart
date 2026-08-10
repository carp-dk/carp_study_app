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

  /// The BLE name prefix used to filter scan results to devices of this type
  /// (e.g. "Polar", "Movesense"). Null for non-BLE devices.
  String? get bleNamePrefix {
    final config = deviceManager.configuration;
    if (config is! BLEDevice) return null;
    final configured = config.namePrefix?.trim();
    return (configured != null && configured.isNotEmpty) ? configured : null;
  }

  /// A printer-friendly name for this device.
  ///
  /// The BLE name of a disconnected device is only a remembered pairing, so it
  /// is not shown - otherwise the device looks connected while offering a
  /// 'connect' action.
  String get name {
    if (deviceManager is BLEDeviceManager) {
      if (status == DeviceStatus.disconnected || status == DeviceStatus.configured) return '';
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
      // Use pair() so device-specific onPaired() runs (e.g. Polar derives its
      // identifier from the BLE name), not just setting the fields directly.
      (deviceManager as BLEDeviceManager).pair(
        bleAddress: selectedDevice.remoteId.str,
        bleName: selectedDevice.platformName,
      );
    }

    deviceManager.connect();
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
  DeviceStatus.reconnected: Icon(Icons.bluetooth_searching_rounded, color: CACHET.DARK_BLUE, size: 30),
  DeviceStatus.connected: Icon(Icons.bluetooth_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.disconnecting: Icon(Icons.bluetooth_searching_rounded, color: CACHET.DARK_BLUE, size: 30),
  DeviceStatus.disconnected: "pages.devices.status.action.connect",
  DeviceStatus.paired: "pages.devices.status.action.connect",
  DeviceStatus.unknown: Icon(Icons.error_outline, color: CACHET.RED_1, size: 30),
};

const Map<DeviceStatus, dynamic> _serviceStatusIcon = {
  DeviceStatus.configured: "pages.devices.status.action.connect",
  DeviceStatus.connecting: Icon(Icons.sensors_off_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.reconnected: Icon(Icons.sensors_off_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.connected: Icon(Icons.sensors_rounded, color: CACHET.GREEN_1, size: 30),
  DeviceStatus.disconnecting: Icon(Icons.sensors_off_rounded, color: CACHET.GREEN_1, size: 30),
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
