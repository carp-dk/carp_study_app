part of carp_study_app;

/// Base view model - a [ChangeNotifier] that notifies its listeners
/// (incl. [ListenableBuilder] widgets) when changed.
abstract class ViewModel extends ChangeNotifier {
  SmartphoneStudyController? _controller;

  SmartphoneStudyController? get controller => _controller;

  /// The measurements the cards source from - generated ones in demo mode,
  /// which stands in for the sensors entirely rather than mixing with them.
  @protected
  Stream<Measurement>? get measurements =>
      AppConfig.demoMode ? DemoDataService().measurements : controller?.measurements;

  /// Initialize this view model before use.
  @mustCallSuper
  void init(SmartphoneStudyController ctrl) {
    _controller = ctrl;
  }

  /// The role name of the device of [deviceType] in the current deployment,
  /// or null if not loaded / not included - data streams are keyed by role.
  @protected
  String? roleOf(String deviceType) =>
      controller?.deployment?.devices.where((device) => device.type == deviceType).firstOrNull?.roleName;

  /// Log and ignore measurement stream errors so sensing can continue.
  void onMeasurementStreamError(Object error, [StackTrace? stackTrace]) {
    warning('$runtimeType - measurement stream error: $error');
  }

  /// Clear this view model, i.e. delete all data incl. cached data.
  @mustCallSuper
  void clear() {}

  /// Called when this view model is disposed. Typically on app exit, incl. when
  /// closed by the OS.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }
}

/// A serializable data model to be used in a [SerializableViewModel].
abstract class DataModel {
  DataModel();
  DataModel fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

/// A view model holding an aggregated [DataModel] behind a card. Not
/// persisted - every card is rebuilt from backfill and/or live probes.
abstract class SerializableViewModel<D extends DataModel> extends ViewModel {
  /// The current data model, fresh on every [init].
  D get model => _model;
  late D _model;

  SerializableViewModel() {
    _model = createModel();
  }

  /// Create the [DataModel] this view model aggregates into.
  @protected
  D createModel();

  @override
  @mustCallSuper
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _model = createModel();
  }
}

/// A measure for a specific week day. [weekday] is numbered in accordance with
/// Dart [DateTime] a week starts with Monday, which has the value 1.
class DailyMeasure {
  /// Day of week - Monday = 1, Sunday = 7.
  final int weekday;

  DailyMeasure(this.weekday);

  /// Get the localized name of the [weekday].
  @override
  String toString() => DateFormat('EEEE').format(DateTime(2021, 2, 7).add(Duration(days: weekday))).substring(0, 3);
}

/// A measure for a specific hour of the day. [hour] and [minute] is the time of the day in 24 hour format.
/// [hour] is numbered in accordance with Dart [DateTime] a day starts with 0.
class HourlyMeasure {
  final int hour;
  final int minute;

  HourlyMeasure(this.hour, this.minute);

  @override
  String toString() => '$hour:$minute';
}

/// The root view model - owns one instance of every page view model and
/// forwards [init], [clear], and [dispose] to them.
class AppViewModel extends ViewModel {
  final HomePageViewModel _homePageViewModel = HomePageViewModel();
  final LoginViewModel _loginViewModel = LoginViewModel();
  final StatisticsViewModel _statisticsViewModel = StatisticsViewModel();
  final StudyPageViewModel _studyPageViewModel = StudyPageViewModel();
  final TaskListPageViewModel _taskListPageViewModel = TaskListPageViewModel();
  final ProfilePageViewModel _profilePageViewModel = ProfilePageViewModel();
  final DeviceListPageViewModel _devicesPageViewModel = DeviceListPageViewModel();
  final InvitationsViewModel _invitationsListViewModel = InvitationsViewModel();
  final InformedConsentViewModel _informedConsentViewModel = InformedConsentViewModel();
  final ParticipantDataPageViewModel _participantDataPageViewModel = ParticipantDataPageViewModel();

  AppViewModel() : super();

  HomePageViewModel get homePageViewModel => _homePageViewModel;
  LoginViewModel get loginViewModel => _loginViewModel;
  StatisticsViewModel get statisticsViewModel => _statisticsViewModel;
  StudyPageViewModel get studyPageViewModel => _studyPageViewModel;
  TaskListPageViewModel get taskListPageViewModel => _taskListPageViewModel;
  ProfilePageViewModel get profilePageViewModel => _profilePageViewModel;
  DeviceListPageViewModel get devicesPageViewModel => _devicesPageViewModel;
  InvitationsViewModel get invitationsListViewModel => _invitationsListViewModel;
  InformedConsentViewModel get informedConsentViewModel => _informedConsentViewModel;
  ParticipantDataPageViewModel get participantDataPageViewModel => _participantDataPageViewModel;

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _homePageViewModel.init(ctrl);
    _taskListPageViewModel.init(ctrl);
    _studyPageViewModel.init(ctrl);
    _statisticsViewModel.init(ctrl);
    _devicesPageViewModel.init(ctrl);

    _profilePageViewModel.init(ctrl);
    _invitationsListViewModel.init(ctrl);
    _informedConsentViewModel.init(ctrl);
    _participantDataPageViewModel.init(ctrl);
  }

  @override
  void clear() {
    _homePageViewModel.clear();
    _taskListPageViewModel.clear();
    _studyPageViewModel.clear();
    _statisticsViewModel.clear();
    _devicesPageViewModel.clear();

    _profilePageViewModel.clear();
    _informedConsentViewModel.clear();

    super.clear();
  }

  @override
  void dispose() {
    _homePageViewModel.dispose();
    _taskListPageViewModel.dispose();
    _studyPageViewModel.dispose();
    _statisticsViewModel.dispose();
    _devicesPageViewModel.dispose();

    _profilePageViewModel.dispose();
    _invitationsListViewModel.dispose();
    _informedConsentViewModel.dispose();

    super.dispose();
  }
}
