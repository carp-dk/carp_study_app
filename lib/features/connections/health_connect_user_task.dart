import 'package:flutter/material.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_study_app/features/connections/health_service_connect_page.dart';

/// A protocol health task - connects to Apple Health / Health Connect like the
/// Connections page, then collects the health data types the protocol asks for.
class HealthConnectUserTask extends UserTask {
  HealthConnectUserTask(super.executor);

  @override
  bool get hasWidget => true;

  @override
  Widget? get widget => HealthServiceConnectPage(userTask: this);
}
