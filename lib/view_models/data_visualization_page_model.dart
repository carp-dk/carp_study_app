part of carp_study_app;

class DataVisualizationPageViewModel extends ViewModel {
  DataVisualizationPageViewModel({StudyService? studyService}) : _studyService = studyService;

  final StudyService? _studyService;
  StudyService get _study => _studyService ?? bloc.study;

  bool _hasUserTasks = false;
  bool _hasHeartRateMeasure = false;
  bool _hasAudioMeasure = false;
  bool _hasVideoMeasure = false;
  bool _hasImageMeasure = false;
  bool _hasStepsMeasure = false;
  bool _hasActivityMeasure = false;
  bool _hasMobilityMeasure = false;

  // Card availability for the current deployment, computed once in [init].
  bool get hasUserTasks => _hasUserTasks;
  bool get hasHeartRateMeasure => _hasHeartRateMeasure;
  bool get hasAudioMeasure => _hasAudioMeasure;
  bool get hasVideoMeasure => _hasVideoMeasure;
  bool get hasImageMeasure => _hasImageMeasure;
  bool get hasStepsMeasure => _hasStepsMeasure;
  bool get hasActivityMeasure => _hasActivityMeasure;
  bool get hasMobilityMeasure => _hasMobilityMeasure;

  final ActivityCardViewModel _activityCardDataModel = ActivityCardViewModel();
  final StepsCardViewModel _stepsCardDataModel = StepsCardViewModel();
  final MeasurementsCardViewModel _measuresCardDataModel = MeasurementsCardViewModel();
  final MobilityCardViewModel _mobilityCardDataModel = MobilityCardViewModel();
  final TaskCardViewModel _surveysCardDataModel = TaskCardViewModel(AppTask.SURVEY_TYPE);
  final TaskCardViewModel _audioCardDataModel = TaskCardViewModel(AppTask.AUDIO_TYPE);
  final TaskCardViewModel _videoCardDataModel = TaskCardViewModel(AppTask.VIDEO_TYPE);
  final TaskCardViewModel _imageCardDataModel = TaskCardViewModel(AppTask.IMAGE_TYPE);
  final StudyProgressCardViewModel _studyProgressCardDataModel = StudyProgressCardViewModel();
  final HeartRateCardViewModel _heartRateCardDataModel = HeartRateCardViewModel();

  ActivityCardViewModel get activityCardDataModel => _activityCardDataModel;
  StepsCardViewModel get stepsCardDataModel => _stepsCardDataModel;
  MeasurementsCardViewModel get measuresCardDataModel => _measuresCardDataModel;
  MobilityCardViewModel get mobilityCardDataModel => _mobilityCardDataModel;
  TaskCardViewModel get surveysCardDataModel => _surveysCardDataModel;
  TaskCardViewModel get audioCardDataModel => _audioCardDataModel;
  TaskCardViewModel get videoCardDataModel => _videoCardDataModel;
  TaskCardViewModel get imageCardDataModel => _imageCardDataModel;
  HeartRateCardViewModel get heartRateCardDataModel => _heartRateCardDataModel;

  StudyProgressCardViewModel get studyProgressCardDataModel => _studyProgressCardDataModel;

  /// A stream of [UserTask]s as they are generated.
  Stream<UserTask> get userTaskEvents => AppTaskController().userTaskEvents;

  /// The number of days the user has been part of this study.
  int get daysInStudy => (bloc.study.studyStartTimestamp != null)
      ? DateTime.now().difference(bloc.study.studyStartTimestamp!).inDays + 1
      : 0;

  /// The number of tasks completed so far.
  int get taskCompleted => AppTaskController().userTaskQueue.where((task) => task.state == UserTaskState.done).length;

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);

    _hasUserTasks = _study.hasUserTasks();
    _hasHeartRateMeasure = _study.hasMeasure(PolarSamplingPackage.HR) || _study.hasMeasure(MovesenseSamplingPackage.HR);
    _hasAudioMeasure = _study.hasMeasure(MediaSamplingPackage.AUDIO);
    _hasVideoMeasure = _study.hasMeasure(MediaSamplingPackage.VIDEO);
    _hasImageMeasure = _study.hasMeasure(MediaSamplingPackage.IMAGE);
    _hasStepsMeasure = _study.hasMeasure(CarpDataTypes.STEP_COUNT);
    _hasActivityMeasure = _study.hasMeasure(ContextSamplingPackage.ACTIVITY);
    _hasMobilityMeasure = _study.hasMeasure(ContextSamplingPackage.MOBILITY);

    _activityCardDataModel.init(ctrl);
    _stepsCardDataModel.init(ctrl);
    _heartRateCardDataModel.init(ctrl);
    _mobilityCardDataModel.init(ctrl);
    _measuresCardDataModel.init(ctrl);
    _surveysCardDataModel.init(ctrl);
    _audioCardDataModel.init(ctrl);
    _videoCardDataModel.init(ctrl);
    _imageCardDataModel.init(ctrl);
    _studyProgressCardDataModel.init(ctrl);
  }

  @override
  void clear() {
    _activityCardDataModel.clear();
    _stepsCardDataModel.clear();
    _heartRateCardDataModel.clear();
    _mobilityCardDataModel.clear();
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
    _heartRateCardDataModel.dispose();
    _mobilityCardDataModel.dispose();
    _measuresCardDataModel.dispose();
    _surveysCardDataModel.dispose();
    _audioCardDataModel.dispose();
    _videoCardDataModel.dispose();
    _imageCardDataModel.dispose();
    _studyProgressCardDataModel.dispose();

    super.dispose();
  }
}
