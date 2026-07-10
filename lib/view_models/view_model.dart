part of carp_study_app;

/// An abstract view model used for all view models in the app.
///
/// Note that a view model is a [ChangeNotifier] and will notify its listeners
/// if changed, including any [ListenableBuilder] widgets.
abstract class ViewModel extends ChangeNotifier {
  SmartphoneStudyController? _controller;

  SmartphoneStudyController? get controller => _controller;

  /// Initialize this view model before use.
  @mustCallSuper
  void init(SmartphoneStudyController ctrl) {
    _controller = ctrl;
  }

  /// Handle errors emitted on a measurement stream.
  ///
  /// Stream errors are not measurements and should not be handled in the data
  /// path. View models should log and ignore them so sensing can continue.
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

/// An abstract view model which can serialize its [DataModel] across app restart.
abstract class SerializableViewModel<D extends DataModel> extends ViewModel {
  String? _filename;
  Timer? _persistenceTimer;

  /// The current data model.
  ///
  /// The data model is either created using the [createModel] method or loaded
  /// from persistent storage.
  D get model => _model;
  late D _model;

  SerializableViewModel() {
    _model = createModel();
  }

  /// The [DataModel] to be serialized.
  ///
  /// Subclasses should override this method to return a newly created instance
  /// of their associated [DataModel] subclass. For example:
  ///
  /// ```dart
  /// @override
  /// MyDataModel createModel() => MyDataModel();
  /// ```
  @protected
  D createModel();

  @override
  @mustCallSuper
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _model = createModel();

    // restore the data model (if any saved)
    restore().then((savedModel) {
      _model = savedModel ?? _model;
      notifyListeners();
    });

    // save the data model on a regular basis.
    _persistenceTimer = Timer.periodic(const Duration(minutes: 3), (_) => save());

    /// Check if we are running in a test environment.
    /// If so, do not listen to app lifecycle events.
    /// [AppLifecycleListener] is not supported in a test environment.
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      AppLifecycleListener(onHide: () async => await save());
    }
  }

  @override
  void clear() {
    super.clear();
    _filename = null;
    _persistenceTimer?.cancel();
    _persistenceTimer = null;
    delete();
  }

  @override
  void dispose() {
    _filename = null;
    _persistenceTimer?.cancel();
    _persistenceTimer = null;

    save().then((_) => super.dispose());
  }

  /// Current path and filename of the cache of the model.
  Future<String> get filename async {
    String path = await LocalSettings().cacheBasePath ?? '';
    _filename = '$path/$runtimeType.json';
    return _filename!;
  }

  /// Persistently save the [model].
  /// Returns true if successful, false otherwise.
  Future<bool> save() async {
    bool success = true;
    try {
      var json = model.toJson();
      String name = (await filename);
      debug("Saving $runtimeType data to file '$name'.");
      File(name).writeAsStringSync(jsonEncode(json));
    } catch (exception) {
      success = false;
      warning('Failed to save $runtimeType - $exception');
    }
    return success;
  }

  /// Permanently delete the cached [model].
  /// Returns true if successful, false otherwise.
  bool delete() {
    bool success = true;
    try {
      if (_filename != null) {
        debug("Deleting $runtimeType data from file '$_filename'.");
        File(_filename!).deleteSync();
      }
    } catch (exception) {
      success = false;
      warning('Failed to delete $runtimeType data - $exception');
    }
    return success;
  }

  /// Restore the [model] from persistent storage.
  /// Returns null if unsuccessful.
  Future<D?> restore() async {
    D? result;
    try {
      String name = (await filename);
      debug("Restoring $runtimeType data from file '$name'.");
      final jsonString = File(name).readAsStringSync();
      final modelAsJson = json.decode(jsonString) as Map<String, dynamic>;
      result = model.fromJson(modelAsJson) as D;
    } catch (exception) {
      warning('Failed to load $runtimeType - $exception');
    }
    return result;
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

/// The view model for the entire app.
class AppViewModel extends ViewModel {
  final HomePageViewModel _homePageViewModel = HomePageViewModel();
  final LoginViewModel _loginViewModel = LoginViewModel();
  final DataVisualizationPageViewModel _dataVisualizationPageViewModel = DataVisualizationPageViewModel();
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
  DataVisualizationPageViewModel get dataVisualizationPageViewModel => _dataVisualizationPageViewModel;
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
    _dataVisualizationPageViewModel.init(ctrl);
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
    _dataVisualizationPageViewModel.clear();
    _devicesPageViewModel.clear();

    _profilePageViewModel.clear();
    _invitationsListViewModel.clear();
    _informedConsentViewModel.clear();

    super.clear();
  }

  @override
  void dispose() {
    _homePageViewModel.dispose();
    _taskListPageViewModel.dispose();
    _studyPageViewModel.dispose();
    _dataVisualizationPageViewModel.dispose();
    _devicesPageViewModel.dispose();

    _profilePageViewModel.dispose();
    _invitationsListViewModel.dispose();
    _informedConsentViewModel.dispose();

    super.dispose();
  }
}
