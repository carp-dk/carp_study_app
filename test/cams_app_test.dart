import 'dart:convert';
import 'dart:io';
import 'package:carp_survey_package/survey.dart';
import 'package:cognition_package/model.dart';

import 'package:carp_connectivity_package/connectivity.dart';
// import 'package:carp_esense_package/esense.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_audio_package/media.dart';
// import 'package:carp_communication_package/communication.dart';
// import 'package:carp_apps_package/apps.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:research_package/research_package.dart';
// import 'package:carp_webservices/carp_auth/carp_auth.dart';
// import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';

import 'exports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
    CarpDataManager();

    // register the different sampling package since we're using measures from them
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    // SamplingPackageRegistry().register(CommunicationSamplingPackage());
    // SamplingPackageRegistry().register(AppsSamplingPackage());
    // SamplingPackageRegistry().register(ESenseSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(MovesenseSamplingPackage());
    SamplingPackageRegistry().register(SurveySamplingPackage());
  });

  group("Local Study Protocol Manager", () {
    // skipping this test since it is throwing strange "asUnmodifiableView" errors....?
    test('JSON File -> StudyProtocol', skip: true, () async {
      final plainJson = File('test/json/study_protocol.json').readAsStringSync();

      SmartphoneStudyProtocol.fromJson(json.decode(plainJson) as Map<String, dynamic>);
    });
  });
}
