import 'dart:io';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_polar_package/carp_polar_package.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
import 'package:carp_aware_package/carp_aware_package.dart';

/// Health data lives in Apple Health on iOS and Health Connect on Android.
String get healthPlatformName => Platform.isIOS ? 'Apple Health' : 'Health Connect';

/// The name of a device [type], for `locale.translate`: brands as-is (translate
/// returns them unchanged), generic sources as a key since "Phone" is "Mobiltelefon" in Danish.
String deviceTypeName(String? type) => switch (type) {
  HealthService.DEVICE_TYPE => healthPlatformName,
  PolarDevice.DEVICE_TYPE => 'Polar',
  MovesenseDevice.DEVICE_TYPE => 'Movesense',
  AppleWatchDevice.DEVICE_TYPE => 'Apple Watch',
  Smartphone.DEVICE_TYPE => 'pages.connections.type.smartphone.name',
  WeatherService.DEVICE_TYPE => 'pages.connections.type.weather.name',
  AirQualityService.DEVICE_TYPE => 'pages.connections.type.air_quality.name',
  LocationService.DEVICE_TYPE => 'pages.connections.type.location.name',
  _ => 'pages.connections.type.unknown.name',
};
