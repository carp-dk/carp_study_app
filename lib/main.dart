// ignore: unnecessary_library_name
library carp_study_app;

import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:app_version_update/data/models/app_version_result.dart';

import 'package:flutter/gestures.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:open_settings_plus/open_settings_plus.dart';
import 'package:open_settings_plus/core/open_settings_plus.dart';
import 'package:appcheck/appcheck.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shimmer/shimmer.dart';
import 'package:app_version_update/app_version_update.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// the CARP packages
import 'package:carp_serializable/carp_serializable.dart';
// Both carp_core and carp_mobile_sensing export `Smartphone`; hide carp_core's.
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_audio_package/media.dart';
import 'package:carp_connectivity_package/connectivity.dart' show ConnectivitySamplingPackage;
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
import 'package:carp_aware_package/carp_aware_package.dart';
import 'package:carp_themes_package/carp_themes_package.dart';

part 'app/app_bloc.dart';
part 'app/app_view_model.dart';
part 'app/carp_app_shell.dart';
part 'app/carp_study_app.dart';
part 'app/user_task_factory.dart';

part 'core/routes.dart';
part 'core/sensing/device_names.dart';
part 'core/backend/backend.dart';
part 'core/backend/carp_backend.dart';
part 'core/backend/local_backend.dart';
part 'core/backend/local_participation_service.dart';
part 'core/backend/local_resource_manager.dart';
part 'core/backend/localization_loader.dart';
part 'core/backend/resource_manager_factory.dart';
part 'core/sensing/background_sensing_service.dart';
part 'core/sensing/sensing.dart';
part 'core/services/auth_service.dart';
part 'core/services/consent_pdf.dart';
part 'core/services/consent_service.dart';
part 'core/services/data_stream_query_service.dart';
part 'core/services/message_service.dart';
part 'core/services/study_service.dart';
part 'core/services/system_info_service.dart';
part 'core/settings/local_settings.dart';
part 'core/settings/participant.dart';
part 'core/util/app_config.dart';
part 'core/util/app_log.dart';
part 'core/util/util.dart';

part 'shared/view_model.dart';
part 'shared/widgets/carp_app_bar.dart';
part 'shared/widgets/error_page.dart';
part 'shared/widgets/dialog_title.dart';
part 'shared/widgets/enable_connection_dialog.dart';
part 'shared/widgets/studies_material.dart';

part 'features/onboarding/code_sign_in_page.dart';
part 'features/onboarding/informed_consent_page.dart';
part 'features/onboarding/informed_consent_view_model.dart';
part 'features/onboarding/invitation_details_page.dart';
part 'features/onboarding/invitation_list_page.dart';
part 'features/onboarding/invitations_view_model.dart';
part 'features/onboarding/login_page.dart';
part 'features/onboarding/login_view_model.dart';
part 'features/onboarding/logout_message.dart';
part 'features/onboarding/qr_to_carp_morph.dart';

part 'features/study/connections_status_card.dart';
part 'features/study/home_page.dart';
part 'features/study/home_view_model.dart';
part 'features/study/message_details_page.dart';
part 'features/study/message_type_icon.dart';
part 'features/study/study_about_page.dart';
part 'features/study/study_view_model.dart';

part 'features/tasks/audio_page.dart';
part 'features/tasks/audio_task_page.dart';
part 'features/tasks/camera_page.dart';
part 'features/tasks/camera_task_page.dart';
part 'features/tasks/display_picture_page.dart';
part 'features/tasks/participant_data_page.dart';
part 'features/tasks/participant_data_view_model.dart';
part 'features/tasks/task_list_page.dart';
part 'features/tasks/task_list_view_model.dart';
part 'features/tasks/user_tasks.dart';

part 'features/statistics/cards/activity_card.dart';
part 'features/statistics/cards/activity_data_model.dart';
part 'features/statistics/cards/distance_card.dart';
part 'features/statistics/cards/heart_rate_card.dart';
part 'features/statistics/cards/heart_rate_data_model.dart';
part 'features/statistics/cards/measurements_data_model.dart';
part 'features/statistics/cards/mobility_card.dart';
part 'features/statistics/cards/mobility_data_model.dart';
part 'features/statistics/cards/sleep_card.dart';
part 'features/statistics/cards/sleep_data_model.dart';
part 'features/statistics/cards/steps_card.dart';
part 'features/statistics/cards/steps_data_model.dart';
part 'features/statistics/cards/study_progress_card.dart';
part 'features/statistics/cards/study_progress_data_model.dart';
part 'features/statistics/cards/survey_card.dart';
part 'features/statistics/cards/task_completion_card.dart';
part 'features/statistics/cards/task_data_model.dart';
part 'features/statistics/chart_helpers.dart';
part 'features/statistics/statistics_page.dart';
part 'features/statistics/statistics_view_model.dart';

part 'features/connections/apple_watch_connect_page.dart';
part 'features/connections/battery_icon.dart';
part 'features/connections/bluetooth_connection_page.dart';
part 'features/connections/carp_sphere_morph.dart';
part 'features/connections/connection_list_page.dart';
part 'features/connections/connection_view_model.dart';
part 'features/connections/enable_bluetooth_dialog.dart';
part 'features/connections/health_connect_user_task.dart';
part 'features/connections/health_service_connect_page.dart';
part 'features/connections/list_title.dart';
part 'features/connections/live_data_page.dart';

part 'features/profile/anonymous_card.dart';
part 'features/profile/profile_page.dart';
part 'features/profile/profile_view_model.dart';

part 'main.g.dart';

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
