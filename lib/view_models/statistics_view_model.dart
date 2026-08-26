part of carp_study_app;

/// View model for [StatisticsPage] - which measures the deployment collects,
/// plus one view model per card. The page only lays the results out.
class StatisticsViewModel extends ViewModel {
  StatisticsViewModel({StudyService? studyService, DataStreamQueryService? queryService})
    : _studyService = studyService,
      _queryService = queryService ?? DataStreamQueryService();

  final StudyService? _studyService;
  StudyService get _study => _studyService ?? bloc.study;

  bool _hasUserTasks = false;
  bool _hasPolarHeartRateMeasure = false;
  bool _hasMovesenseHeartRateMeasure = false;
  bool _hasAudioMeasure = false;
  bool _hasVideoMeasure = false;
  bool _hasImageMeasure = false;

  bool _hasStepsMeasure = false;
  bool _hasActivityMeasure = false;
  bool _hasMobilityMeasure = false;
  bool _hasSleepMeasure = false;

  // Card availability for the current deployment, computed once in [init].
  bool get hasUserTasks => _hasUserTasks;
  bool get hasPolarHeartRateMeasure => _hasPolarHeartRateMeasure;
  bool get hasMovesenseHeartRateMeasure => _hasMovesenseHeartRateMeasure;
  bool get hasAudioMeasure => _hasAudioMeasure;
  bool get hasVideoMeasure => _hasVideoMeasure;
  bool get hasImageMeasure => _hasImageMeasure;
  bool get hasStepsMeasure => _hasStepsMeasure;
  bool get hasActivityMeasure => _hasActivityMeasure;
  bool get hasMobilityMeasure => _hasMobilityMeasure;
  bool get hasSleepMeasure => _hasSleepMeasure;

  final ActivityCardViewModel _activityCardDataModel = ActivityCardViewModel();
  final StepsCardViewModel _stepsCardDataModel = StepsCardViewModel();
  final MeasurementsCardViewModel _measuresCardDataModel = MeasurementsCardViewModel();
  final MobilityCardViewModel _mobilityCardDataModel = MobilityCardViewModel();
  final SleepCardViewModel _sleepCardDataModel = SleepCardViewModel();
  final TaskCardViewModel _surveysCardDataModel = TaskCardViewModel(AppTask.SURVEY_TYPE);
  final TaskCardViewModel _audioCardDataModel = TaskCardViewModel(AppTask.AUDIO_TYPE);
  final TaskCardViewModel _videoCardDataModel = TaskCardViewModel(AppTask.VIDEO_TYPE);
  final TaskCardViewModel _imageCardDataModel = TaskCardViewModel(AppTask.IMAGE_TYPE);
  final StudyProgressCardViewModel _studyProgressCardDataModel = StudyProgressCardViewModel();
  final HeartRateCardViewModel _polarHeartRateCardDataModel = HeartRateCardViewModel(
    PolarSamplingPackage.HR,
    PolarDevice.DEVICE_TYPE,
  );
  final HeartRateCardViewModel _movesenseHeartRateCardDataModel = HeartRateCardViewModel(
    MovesenseSamplingPackage.HR,
    MovesenseDevice.DEVICE_TYPE,
  );

  ActivityCardViewModel get activityCardDataModel => _activityCardDataModel;
  StepsCardViewModel get stepsCardDataModel => _stepsCardDataModel;
  MeasurementsCardViewModel get measuresCardDataModel => _measuresCardDataModel;
  MobilityCardViewModel get mobilityCardDataModel => _mobilityCardDataModel;
  SleepCardViewModel get sleepCardDataModel => _sleepCardDataModel;
  TaskCardViewModel get surveysCardDataModel => _surveysCardDataModel;
  TaskCardViewModel get audioCardDataModel => _audioCardDataModel;
  TaskCardViewModel get videoCardDataModel => _videoCardDataModel;
  TaskCardViewModel get imageCardDataModel => _imageCardDataModel;
  HeartRateCardViewModel get polarHeartRateCardDataModel => _polarHeartRateCardDataModel;
  HeartRateCardViewModel get movesenseHeartRateCardDataModel => _movesenseHeartRateCardDataModel;

  StudyProgressCardViewModel get studyProgressCardDataModel => _studyProgressCardDataModel;

  final DataStreamQueryService _queryService;

  bool _isRefreshing = false;

  /// A stream of [UserTask]s as they are generated.
  Stream<UserTask> get userTaskEvents => AppTaskController().userTaskEvents;

  /// The number of tasks completed so far.
  int get taskCompleted => AppTaskController().userTaskQueue.where((task) => task.state == UserTaskState.done).length;

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    _hasUserTasks = _study.hasUserTasks();
    _hasPolarHeartRateMeasure = _study.hasMeasure(PolarSamplingPackage.HR);
    _hasMovesenseHeartRateMeasure = _study.hasMeasure(MovesenseSamplingPackage.HR);
    _hasAudioMeasure = _study.hasMeasure(MediaSamplingPackage.AUDIO);
    _hasVideoMeasure = _study.hasMeasure(MediaSamplingPackage.VIDEO);
    _hasImageMeasure = _study.hasMeasure(MediaSamplingPackage.IMAGE);
    _hasStepsMeasure = StepsCardViewModel.dataTypes.any(_study.hasMeasure);
    _hasActivityMeasure = _study.hasMeasure(ContextSamplingPackage.ACTIVITY);
    _hasMobilityMeasure = _study.hasMeasure(ContextSamplingPackage.MOBILITY);
    // A health measure may or may not include sleep types, but the card's
    // hasData gate hides it either way until sleep actually arrives.
    _hasSleepMeasure = _study.hasMeasure(HealthSamplingPackage.HEALTH);

    _activityCardDataModel.init(ctrl);
    _stepsCardDataModel.init(ctrl);
    _polarHeartRateCardDataModel.init(ctrl);
    _movesenseHeartRateCardDataModel.init(ctrl);
    _mobilityCardDataModel.init(ctrl);
    _sleepCardDataModel.init(ctrl);
    _measuresCardDataModel.init(ctrl);
    _surveysCardDataModel.init(ctrl);
    _audioCardDataModel.init(ctrl);
    _videoCardDataModel.init(ctrl);
    _imageCardDataModel.init(ctrl);
    _studyProgressCardDataModel.init(ctrl);
  }

  /// Fetch the last 7 days from CAWS and recompute the cards. Best-effort:
  /// a failed fetch leaves existing card data untouched. No-op while running.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      await Future.wait([
        // A study declares one of the two pedometer types (legacy STEP_COUNT
        // or STEP_EVENT) - fetch whichever it is.
        if (hasStepsMeasure)
          _fetchInto(StepsCardViewModel.dataTypes.firstWhere(_study.hasMeasure), _stepsCardDataModel.addMeasurements),
        if (hasActivityMeasure) _fetchInto(ContextSamplingPackage.ACTIVITY, _activityCardDataModel.addMeasurements),
        // Mobility and health are produced by their connected service, so
        // their streams are keyed by that service's role, not the phone's
        // (falling back to the phone when a protocol runs them there).
        if (hasMobilityMeasure)
          _fetchInto(
            ContextSamplingPackage.MOBILITY,
            _mobilityCardDataModel.addMeasurements,
            deviceRoleName: _mobilityCardDataModel.deviceRoleName,
          ),
        // Health data all arrives on one data type; the sleep card picks its
        // own readings out of the batch.
        // ponytail: health completed via an app task streams under the phone
        // role instead - not fetched; backfill covers the background stream.
        if (hasSleepMeasure)
          _fetchInto(
            HealthSamplingPackage.HEALTH,
            _sleepCardDataModel.addMeasurements,
            deviceRoleName: _sleepCardDataModel.deviceRoleName,
          ),
        // Heart rate is recorded by the sensor's own device role, not the
        // phone's - skip the fetch if that device isn't in the deployment
        // (nothing to query, and a null role would silently query the phone).
        if (hasPolarHeartRateMeasure && _polarHeartRateCardDataModel.deviceRoleName != null)
          _fetchInto(
            _polarHeartRateCardDataModel.dataType,
            _polarHeartRateCardDataModel.addMeasurements,
            deviceRoleName: _polarHeartRateCardDataModel.deviceRoleName,
          ),
        if (hasMovesenseHeartRateMeasure && _movesenseHeartRateCardDataModel.deviceRoleName != null)
          _fetchInto(
            _movesenseHeartRateCardDataModel.dataType,
            _movesenseHeartRateCardDataModel.addMeasurements,
            deviceRoleName: _movesenseHeartRateCardDataModel.deviceRoleName,
          ),
      ]);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Fetch [dataType] and hand it to [into] - on failure the card keeps what
  /// it already has.
  Future<void> _fetchInto(String dataType, void Function(List<Measurement>) into, {String? deviceRoleName}) async {
    final measurements = await _queryService.fetch(dataType, deviceRoleName: deviceRoleName);
    if (measurements != null) into(measurements);
  }

  @override
  void clear() {
    _activityCardDataModel.clear();
    _stepsCardDataModel.clear();
    _polarHeartRateCardDataModel.clear();
    _movesenseHeartRateCardDataModel.clear();
    _mobilityCardDataModel.clear();
    _sleepCardDataModel.clear();
    _measuresCardDataModel.clear();
    _surveysCardDataModel.clear();
    _audioCardDataModel.clear();
    _videoCardDataModel.clear();
    _imageCardDataModel.clear();
    _studyProgressCardDataModel.clear();

    super.clear();
  }

  @override
  void dispose() {
    _activityCardDataModel.dispose();
    _stepsCardDataModel.dispose();
    _polarHeartRateCardDataModel.dispose();
    _movesenseHeartRateCardDataModel.dispose();
    _mobilityCardDataModel.dispose();
    _sleepCardDataModel.dispose();
    _measuresCardDataModel.dispose();
    _surveysCardDataModel.dispose();
    _audioCardDataModel.dispose();
    _videoCardDataModel.dispose();
    _imageCardDataModel.dispose();
    _studyProgressCardDataModel.dispose();

    super.dispose();
  }
}
