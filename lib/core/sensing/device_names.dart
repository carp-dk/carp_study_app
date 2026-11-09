part of carp_study_app;

/// Health data lives in Apple Health on iOS and Health Connect on Android.
/// App names are not translated - translate() returns them unchanged.
String get healthPlatformName => Platform.isIOS ? 'Apple Health' : 'Health Connect';

/// The translation key naming a device [type], e.g. 'pages.connections.type.polar.name'.
String deviceTypeName(String? type) => type == HealthService.DEVICE_TYPE
    ? healthPlatformName
    : _deviceTypeName[type] ?? 'pages.connections.type.unknown.name';

const Map<String, String> _deviceTypeName = {
  Smartphone.DEVICE_TYPE: "pages.connections.type.smartphone.name",
  WeatherService.DEVICE_TYPE: "pages.connections.type.weather.name",
  AirQualityService.DEVICE_TYPE: "pages.connections.type.air_quality.name",
  LocationService.DEVICE_TYPE: "pages.connections.type.location.name",
  PolarDevice.DEVICE_TYPE: "pages.connections.type.polar.name",
  MovesenseDevice.DEVICE_TYPE: "pages.connections.type.movesense.name",
  AppleWatchDevice.DEVICE_TYPE: "pages.connections.type.apple_watch.name",
};
