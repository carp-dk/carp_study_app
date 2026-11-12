import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:carp_study_app/app/app_view_model.dart';
import 'package:carp_study_app/app/carp_study_app.dart';
import 'package:carp_study_app/app/user_task_factory.dart';
import 'package:carp_study_app/core/backend/resource_manager_factory.dart';
import 'package:carp_study_app/core/routes.dart';
import 'package:carp_study_app/core/sensing/background_sensing_service.dart';
import 'package:carp_study_app/core/sensing/sensing.dart';
import 'package:carp_study_app/core/services/auth_service.dart';
import 'package:carp_study_app/core/services/consent_service.dart';
import 'package:carp_study_app/core/services/message_service.dart';
import 'package:carp_study_app/core/services/study_service.dart';
import 'package:carp_study_app/core/services/system_info_service.dart';
import 'package:carp_study_app/core/settings/local_settings.dart';
import 'package:carp_study_app/core/settings/participant.dart';
import 'package:carp_study_app/core/util/app_config.dart';

/// The [AppBloc] state, ordered by progress - a state implies the ones before it.
enum AppState {
  /// The BLoC is created but not ready for use.
  created,

  /// The BLoC is initialized via the [initialized] method.
  initialized,

  /// Configuration failed - recover by calling [AppBloc.tryConfigureStudy] again.
  configurationFailed,

  /// The BLoC is in the process of being configured with a study.
  configuring,

  /// The BLoC is configured with a study and ready to use.
  configured,
}

/// The app coordinator: state machine, services, and orchestration. See `bloc`.
class AppBloc extends ChangeNotifier {
  AppState _state = AppState.created;
  final AppViewModel _appViewModel = AppViewModel();
  StreamSubscription<void>? _sessionLostSubscription;
  StreamSubscription<UserTask>? _userTaskNotificationSubscription;
  StreamSubscription<String>? _notificationTapSubscription;

  /// The resource managers matching the current deployment mode.
  late final ResourceManagerFactory resources = ResourceManagerFactory();

  /// Device- and platform-level checks.
  late final SystemInfoService system = SystemInfoService();

  /// User identity and authentication.
  late final AuthService auth = AuthService();

  /// The study running on this phone and its deployment.
  late final StudyService study = StudyService(resources: resources);

  /// The messages shown in the app, kept refreshed by polling.
  late final MessageService messages = MessageService(resources.messageManager);

  /// The informed consent flow.
  late final ConsentService consent = ConsentService(resources.informedConsentManager);

  /// The state of this BloC.
  AppState get state => _state;

  bool get isInitialized => _state.index >= AppState.initialized.index;
  bool get isConfiguring => _state.index >= AppState.configuring.index;
  bool get isConfigured => _state.index >= AppState.configured.index;

  /// The overall data model for this app
  AppViewModel get appViewModel => _appViewModel;

  /// Create the BLoC for the app.
  AppBloc() : super() {
    info(
      '$runtimeType created. '
      'DeploymentMode: ${AppConfig.deploymentMode.name}, '
      'DebugLevel: ${AppConfig.debugLevel.name}',
    );
  }

  /// Run [configureStudy] without throwing. Returns false if it failed.
  Future<bool> tryConfigureStudy() async {
    try {
      await configureStudy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Did the last configuration attempt fail? Shows the error + retry card.
  bool get configurationFailed => _state == AppState.configurationFailed;

  /// Initialize this BLOC. Called before being used for anything.
  Future<void> initialize() async {
    if (isInitialized) return;

    Settings().debugLevel = AppConfig.debugLevel;
    await Settings().init();

    CarpResourceManager().initialize();

    // The app's task types (audio, video, health) - after Sensing(), whose
    // health package registers its own factory for the health type.
    Sensing();
    AppTaskController().registerUserTaskFactory(AppUserTaskFactory());

    // Lost session mid-study: sign out and let the router redirect to login.
    _sessionLostSubscription ??= auth.sessionLost.listen((_) {
      if (isConfigured) signOutAndLeaveStudy();
    });

    // Offline-safe, and configures the deployment service Sensing() needs.
    await auth.initialize();

    _state = AppState.initialized;
    notifyListeners();
    debug('$runtimeType initialized - deployment mode: ${AppConfig.deploymentMode.name}');
  }

  /// Set the active study from an [invitation] - the app re-loads translations.
  void setStudyInvitation(ActiveParticipationInvitation invitation) {
    // create and save the participant info based on this invitation
    LocalSettings().participant = Participant.fromParticipationInvitation(invitation);

    // Also seeds the CAWS services, so they resolve the study's resources.
    study.study = SmartphoneStudy.fromInvitation(invitation);

    // And then re-initialize the resource manager.
    CarpResourceManager().initialize();

    notifyListeners();

    info('Invitation received - study: ${study.study}');
  }

  /// Deploy the study and start sensing - on failure, reset for retry and rethrow.
  Future<void> configureStudy() async {
    // early out if already configuring or configured
    if (_state == AppState.configuring || isConfigured) {
      return;
    }

    _state = AppState.configuring;
    notifyListeners();

    try {
      // Only once there is a study - this asks for notification permissions.
      await Sensing().initialize(study.deploymentService);
      await study.configure();
    } catch (error) {
      _state = AppState.configurationFailed;
      notifyListeners();
      warning('$runtimeType - Study configuration failed - $error');
      rethrow;
    }

    appViewModel.init(study.controller!);

    messages.start();
    _listenToNotifications();

    info('Study configuration done.');

    _state = AppState.configured;
    notifyListeners();

    await study.start();
  }

  /// Open the task page when a task notification is tapped - until [leaveStudy].
  /// Other notifications (announcements) carry the route to open as payload.
  void _listenToNotifications() {
    _userTaskNotificationSubscription ??= AppTaskController().userTaskEvents.listen((userTask) {
      if (userTask.state == UserTaskState.notified) {
        userTask.onStart();
        if (userTask.hasWidget) rootNavigatorKey.currentContext?.push('${Routes.task}/${userTask.id}');
      }
    });
    _notificationTapSubscription ??= SmartPhoneClientManager().notificationManager.notificationTaps.listen(
      (route) => rootNavigatorKey.currentContext?.push(route),
    );
  }

  /// Stop sensing and wipe the study from the phone - data is not recoverable.
  Future<void> leaveStudy() async {
    info('Leaving study ${study.study}');

    // clear the UI data models, message polling, and notification handling
    appViewModel.clear();
    messages.stop();
    await _userTaskNotificationSubscription?.cancel();
    _userTaskNotificationSubscription = null;
    await _notificationTapSubscription?.cancel();
    _notificationTapSubscription = null;

    // stop sensing - including in background - and remove all deployment info
    await BackgroundSensingService().disconnect();
    await study.remove();

    _state = AppState.initialized;
    notifyListeners();
  }

  /// [leaveStudy] plus permanently deleting all authentication from this phone.
  Future<void> signOutAndLeaveStudy() async {
    await auth.signOut();
    await leaveStudy();
  }

  /// Dispose the entire sensing.
  @override
  void dispose() {
    _sessionLostSubscription?.cancel();
    messages.dispose();
    study.controller?.dispose();
    super.dispose();
  }
}
