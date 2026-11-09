import 'package:flutter/material.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:carp_study_app/app/app_bloc.dart';
import 'package:carp_study_app/app/carp_study_app.dart';

late CarpStudyApp app;
void main() async {
  // Platform channels need the WidgetsBinding to exist.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize CAMS and related packages (loading json deserialization functions)
  CarpMobileSensing.ensureInitialized();
  CognitionPackage.ensureInitialized();
  CarpDataManager.ensureInitialized();

  await bloc.initialize();

  app = const CarpStudyApp();
  runApp(app);
}

/// The singleton BLoC.
final bloc = AppBloc();
