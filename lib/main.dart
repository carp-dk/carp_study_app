// ignore: unnecessary_library_name
library carp_study_app;

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:app_version_update/data/models/app_version_result.dart';
import 'package:async/async.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:open_settings_plus/open_settings_plus.dart';
import 'package:open_settings_plus/core/open_settings_plus.dart';
import 'package:appcheck/appcheck.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_version_update/app_version_update.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' as qr;

// the CARP packages
import 'package:carp_serializable/carp_serializable.dart';
// Both carp_core and carp_mobile_sensing export `Smartphone`; hide carp_core's.
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_audio_package/media.dart';
//import 'package:carp_connectivity_package/connectivity.dart';
//import 'package:carp_communication_package/communication.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_survey_package/survey.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_backend/carp_backend.dart';
// import 'package:carp_esense_package/esense.dart';
import 'package:carp_polar_package/carp_polar_package.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:carp_health_package/health_package.dart';
// import 'package:health/health.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
import 'package:carp_themes_package/carp_themes_package.dart';

part 'core/app_bloc.dart';
part 'core/sensing.dart';
part 'core/carp_backend.dart';
part 'core/resource_manager_factory.dart';

part 'helpers/app_config.dart';
part 'helpers/app_log.dart';
part 'helpers/util.dart';

part 'services/system_info_service.dart';
part 'services/auth_service.dart';
part 'services/study_service.dart';
part 'services/message_service.dart';
part 'services/consent_service.dart';

part 'data/local_settings.dart';
part 'data/localization_loader.dart';
part 'data/local_resource_manager.dart';
part 'data/participant.dart';
part 'data/local_participation_service.dart';

part 'view_models/view_model.dart';
part 'view_models/home_view_model.dart';
part 'view_models/login_view_model.dart';
part 'view_models/task_list_view_model.dart';
part 'view_models/study_view_model.dart';
part 'view_models/profile_view_model.dart';
part 'view_models/device_view_model.dart';
part 'view_models/statistics_view_model.dart';
part 'view_models/informed_consent_view_model.dart';
part 'view_models/invitations_view_model.dart';
part 'view_models/participant_data_view_model.dart';
part 'view_models/cards/activity_data_model.dart';
part 'view_models/cards/mobility_data_model.dart';
part 'view_models/cards/steps_data_model.dart';
part 'view_models/cards/heart_rate_data_model.dart';
part 'view_models/cards/measurements_data_model.dart';
part 'view_models/cards/task_data_model.dart';
part 'view_models/cards/study_progress_data_model.dart';
part 'view_models/user_tasks.dart';

part 'carp_study_app.dart';
part 'ui/pages/informed_consent_page.dart';
part 'ui/pages/carp_app_shell.dart';
part 'ui/pages/home_page.dart';
part 'ui/pages/home_page.install_health_connect_dialog.dart';
part 'ui/helpers.dart';
part 'ui/pages/statistics_page.dart';
part 'ui/pages/study_page.dart';
part 'ui/pages/task_list_page.dart';
part 'ui/pages/profile_page.dart';
part 'ui/pages/error_page.dart';
part 'ui/pages/login_page.dart';
part 'ui/pages/qr_scanner.dart';
part 'ui/pages/enable_connection_dialog.dart';
part 'ui/pages/device_list_page.dart';
part 'ui/pages/devices_page.authorization_dialog.dart';
part 'ui/pages/devices_page.enable_bluetooth_dialog.dart';
part 'ui/pages/devices_page.bluetooth_connection_page.dart';
part 'ui/pages/devices_page.list_title.dart';
part 'ui/pages/devices_page.health_service_connect.dart';

part 'ui/tasks/audio_task_page.dart';
part 'ui/tasks/audio_page.dart';
part 'ui/pages/study_about_page.dart';
part 'ui/pages/message_details_page.dart';
part 'ui/pages/invitation_details_page.dart';
part 'ui/pages/invitation_list_page.dart';
part 'ui/pages/process_message_page.dart';
part 'ui/tasks/camera_task_page.dart';
part 'ui/tasks/display_picture_page.dart';
part 'ui/tasks/participant_data_page.dart';
part 'ui/tasks/camera_page.dart';

part 'ui/widgets/carp_app_bar.dart';
part 'ui/widgets/horizontal_bar.dart';
part 'ui/widgets/charts_legend.dart';
part 'ui/widgets/details_banner.dart';
part 'ui/widgets/studies_material.dart';
part 'ui/widgets/battery_icon.dart';
part 'ui/widgets/logout_message.dart';
part 'ui/widgets/dialog_title.dart';

part 'ui/cards/activity_card.dart';
part 'ui/cards/anonymous_card.dart';
part 'ui/cards/connections_status_card.dart';
part 'ui/cards/distance_card.dart';
part 'ui/cards/heart_rate_card.dart';
part 'ui/cards/media_card.dart';
part 'ui/cards/mobility_card.dart';
part 'ui/cards/steps_card.dart';
part 'ui/cards/study_progress_card.dart';
part 'ui/cards/survey_card.dart';
part 'ui/cards/task_completion_card.dart';

part 'main.g.dart';

late CarpStudyApp app;
void main() async {
  // Make sure to have an instance of the WidgetsBinding, which is required
  // to use platform channels to call native code.
  // See also >> https://stackoverflow.com/questions/63873338/what-does-widgetsflutterbinding-ensureinitialized-do/63873689
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
