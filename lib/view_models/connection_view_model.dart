part of carp_study_app;

// Consts, because the icon maps below are const lookups without a BuildContext.
const Color _statusSuccess = Color(0xff67CE67);
const Color _statusError = Color(0xffEB4B62);

/// View model for [ConnectionListPage] - its devices and services as view models.
class ConnectionListPageViewModel extends ViewModel {
  ConnectionListPageViewModel({StudyService? studyService}) : _studyService = studyService;

  final StudyService? _studyService;
  StudyService get _study => _studyService ?? bloc.study;

  /// The smartphone (primary) device of this deployment.
  List<ConnectionViewModel> get smartphoneDevice =>
      _study.deploymentDevices.where((device) => device.deviceManager is SmartphoneDeviceManager).toList();

  /// The hardware devices (connected devices) of this deployment.
  List<ConnectionViewModel> get hardwareDevices => _study.deploymentDevices
      .where(
        (device) => device.deviceManager is HardwareDeviceManager && device.deviceManager is! SmartphoneDeviceManager,
      )
      .toList();

  /// The services of this deployment.
  List<ConnectionViewModel> get services =>
      _study.deploymentDevices.where((device) => device.deviceManager is ServiceManager).toList();
}

/// One device row: name, icon and status of a [DeviceManager]; connects it.
class ConnectionViewModel extends ViewModel {
  DeviceManager deviceManager;
  ConnectionViewModel(this.deviceManager) : super();

  StreamSubscription<DeviceStatus>? _statusSub;

  // Bridge the status stream into notifications - only while listened to, since
  // `deploymentDevices` builds these per call.
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
  String get typeName => type == HealthService.DEVICE_TYPE
      ? healthPlatformName
      : _deviceTypeName[type!] ?? 'pages.connections.type.unknown.name';

  /// The status of this device.
  DeviceStatus get status => deviceManager.status;
  set status(DeviceStatus status) => deviceManager.status = status;

  /// Stream of [DeviceStatus] events
  Stream<DeviceStatus> get statusEvents => deviceManager.statusEvents;

  /// The device id
  String get id => deviceManager.displayName ?? '';

  /// The BLE name prefix scan results are filtered by. Null for non-BLE devices.
  String? get bleNamePrefix {
    final config = deviceManager.configuration;
    if (config is! BLEDevice) return null;
    final configured = config.namePrefix?.trim();
    return (configured != null && configured.isNotEmpty) ? configured : null;
  }

  /// A printable name - a disconnected device's BLE name is only a memory.
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

  /// The battery level, or null if this is not a [HardwareDeviceManager].
  int? get batteryLevel =>
      (deviceManager is HardwareDeviceManager) ? (deviceManager as HardwareDeviceManager).batteryLevel : null;

  /// Battery level events - empty if this is not a [HardwareDeviceManager].
  Stream<int> get batteryEvents => deviceManager is HardwareDeviceManager
      ? (deviceManager as HardwareDeviceManager).batteryEvents
      : const Stream.empty();

  /// The icon for this type of device.
  Icon? get icon => _deviceTypeIcon[type!];

  /// A brand logo shown instead of [icon], if this type of device has one.
  String? get iconImage => switch (type) {
    MovesenseDevice.DEVICE_TYPE => 'assets/icons/movesense_logo.png',
    HealthService.DEVICE_TYPE => healthPlatformIcon,
    _ => null,
  };

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
      // pair(), so device-specific onPaired() runs - not just setting fields.
      (deviceManager as BLEDeviceManager).pair(
        bleAddress: selectedDevice.remoteId.str,
        bleName: selectedDevice.platformName,
      );
    }

    deviceManager.connect();
  }
}

/// Health data lives in Apple Health on iOS and Health Connect on Android.
/// App names are not translated - translate() returns them unchanged.
String get healthPlatformName => Platform.isIOS ? 'Apple Health' : 'Health Connect';

/// A health data type from the protocol as a label, using its 'health.type.TYPE'
/// translation if there is one, e.g. BODY_FAT_PERCENTAGE -> 'Body fat percentage'.
String healthDataTypeLabel(RPLocalizations locale, HealthDataType type) {
  final key = 'health.type.${type.name}';
  final label = locale.translate(key);
  if (label != key) return label;
  final words = type.name.toLowerCase().replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}

String get healthPlatformIcon =>
    Platform.isIOS ? 'assets/instructions/apple_health_icon.png' : 'assets/instructions/google_health_connect_icon.png';

const Map<String, String> _deviceTypeName = {
  Smartphone.DEVICE_TYPE: "pages.connections.type.smartphone.name",
  WeatherService.DEVICE_TYPE: "pages.connections.type.weather.name",
  AirQualityService.DEVICE_TYPE: "pages.connections.type.air_quality.name",
  LocationService.DEVICE_TYPE: "pages.connections.type.location.name",
  PolarDevice.DEVICE_TYPE: "pages.connections.type.polar.name",
  MovesenseDevice.DEVICE_TYPE: "pages.connections.type.movesense.name",
};

const Map<String, String> _deviceTypeDescription = {
  Smartphone.DEVICE_TYPE: "pages.connections.type.smartphone.description",
  WeatherService.DEVICE_TYPE: "pages.connections.type.weather.description",
  AirQualityService.DEVICE_TYPE: "pages.connections.type.air_quality.description",
  LocationService.DEVICE_TYPE: "pages.connections.type.location.description",
  PolarDevice.DEVICE_TYPE: "pages.connections.type.polar.description",
  MovesenseDevice.DEVICE_TYPE: "pages.connections.type.movesense.description",
  HealthService.DEVICE_TYPE: "pages.connections.type.health.description",
};

const Map<String, Icon> _deviceTypeIcon = {
  Smartphone.DEVICE_TYPE: Icon(Icons.phone_android, size: 30, color: _statusSuccess),
  WeatherService.DEVICE_TYPE: Icon(Icons.wb_cloudy, color: Color(0xff2192C9)),
  AirQualityService.DEVICE_TYPE: Icon(Icons.air, color: Color(0xff81CFFA)),
  LocationService.DEVICE_TYPE: Icon(Icons.location_on, color: _statusSuccess),
  PolarDevice.DEVICE_TYPE: Icon(Icons.monitor_heart, size: 30, color: _statusError),
  MovesenseDevice.DEVICE_TYPE: Icon(Icons.circle, size: 30, color: Color(0xff646363)),
  HealthService.DEVICE_TYPE: Icon(Icons.favorite_rounded, size: 30, color: _statusError),
};

const Map<DeviceStatus, dynamic> _deviceStatusIcon = {
  DeviceStatus.configured: "pages.connections.status.action.connect",
  DeviceStatus.connecting: Icon(Icons.bluetooth_searching_rounded, color: Color(0xff3260A4), size: 30),
  DeviceStatus.reconnected: Icon(Icons.bluetooth_searching_rounded, color: Color(0xff3260A4), size: 30),
  DeviceStatus.connected: Icon(Icons.bluetooth_rounded, color: _statusSuccess, size: 30),
  DeviceStatus.disconnecting: Icon(Icons.bluetooth_searching_rounded, color: Color(0xff3260A4), size: 30),
  DeviceStatus.disconnected: "pages.connections.status.action.connect",
  DeviceStatus.paired: "pages.connections.status.action.connect",
  DeviceStatus.unknown: Icon(Icons.error_outline, color: _statusError, size: 30),
};

const Map<DeviceStatus, dynamic> _serviceStatusIcon = {
  DeviceStatus.configured: "pages.connections.status.action.connect",
  DeviceStatus.connecting: Icon(Icons.sensors_off_rounded, color: _statusSuccess, size: 30),
  DeviceStatus.reconnected: Icon(Icons.sensors_off_rounded, color: _statusSuccess, size: 30),
  DeviceStatus.connected: Icon(Icons.sensors_rounded, color: _statusSuccess, size: 30),
  DeviceStatus.disconnecting: Icon(Icons.sensors_off_rounded, color: _statusSuccess, size: 30),
  DeviceStatus.disconnected: "pages.connections.status.action.connect",
  DeviceStatus.paired: "pages.connections.status.action.connect",
  DeviceStatus.unknown: Icon(Icons.error_outline, color: _statusError, size: 30),
};

const Map<DeviceStatus, String> _deviceStatusText = {
  DeviceStatus.connecting: "pages.connections.status.connecting",
  DeviceStatus.connected: "pages.connections.status.connected",
  DeviceStatus.disconnected: "pages.connections.status.disconnected",
  DeviceStatus.paired: "pages.connections.status.paired",
  DeviceStatus.configured: "pages.connections.status.initialized",
  DeviceStatus.unknown: "pages.connections.status.unknown",
};

const Map<String, String> _deviceConnectionInstructions = {
  Smartphone.DEVICE_TYPE: "pages.connections.type.smartphone.instructions",
  PolarDevice.DEVICE_TYPE: "pages.connections.type.polar.instructions",
  MovesenseDevice.DEVICE_TYPE: "pages.connections.type.movesense.instructions",
};

const Map<String, String> _deviceConnectionInstructionsImage = {
  Smartphone.DEVICE_TYPE: "assets/icons/connection_done.png",
  PolarDevice.DEVICE_TYPE: "assets/instructions/polar_h9_h10_instructions.png",
  MovesenseDevice.DEVICE_TYPE: "assets/instructions/movesense_instructions.png",
};
