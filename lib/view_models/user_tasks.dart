part of carp_study_app;

/// A [UserTaskFactory] that can handle the user tasks in this app.
class AppUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [
    SurveyUserTask.AUDIO_TYPE,
    SurveyUserTask.VIDEO_TYPE,
    SurveyUserTask.IMAGE_TYPE,
  ];

  @override
  UserTask create(AppTaskExecutor executor) => switch (executor.task.type) {
        SurveyUserTask.AUDIO_TYPE => AudioUserTask(executor),
        SurveyUserTask.VIDEO_TYPE => VideoUserTask(executor),
        SurveyUserTask.IMAGE_TYPE => VideoUserTask(executor),
        _ => BackgroundSensingUserTask(executor),
      };
}

/// A user task handling audio recordings.
///
/// The [widget] returns an [AudioTaskPage] that can be shown on the UI.
///
/// When the recording is started (calling the [onRecordStart] method),
/// the background task collecting sensor measures is started.
class AudioUserTask extends UserTask {
  StreamController<int>? _countDownController;
  Stream<int>? get countDownEvents => _countDownController?.stream;
  Timer? _timer;

  /// Total duration of audio recording in seconds.
  int recordingDuration = 60;

  /// Seconds left in ongoing recording
  int ongoingRecordingDuration = 60;

  AudioUserTask(AppTaskExecutor executor) : super(executor) {
    recordingDuration = (executor.task.minutesToComplete != null) ? executor.task.minutesToComplete! * 60 : 60;
  }

  @override
  bool get hasWidget => true;

  @override
  Widget? get widget => AudioTaskPage(audioUserTask: this);

  /// Callback when recording is to start.
  void onRecordStart() {
    _countDownController = StreamController.broadcast();
    ongoingRecordingDuration = recordingDuration;
    state = UserTaskState.started;
    backgroundTaskExecutor.start();

    try {
      backgroundTaskExecutor.measurements
          .firstWhere((measurement) => measurement.data is AudioMedia)
          .then((measurement) => super.onDone(result: measurement.data));
    } catch (_) {
      super.onDone();
    }

    // Start the countdown timer and stop the recording when [recordingDuration] is reached
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _countDownController?.add(--ongoingRecordingDuration);

      if (ongoingRecordingDuration <= 0) onRecordStop();
    });
  }

  /// Callback when recording is to stop.
  void onRecordStop() {
    _timer?.cancel();
    _countDownController?.close();
    backgroundTaskExecutor.stop();
  }

  /// Callback when recording is to start.
  void onRecordReset() {
    state = UserTaskState.enqueued;
    _timer?.cancel();
    _countDownController?.close();

    backgroundTaskExecutor.stop();
  }
}

/// A user task handling video and image recordings.
/// When started, creates a [CameraTaskPage].
class VideoUserTask extends UserTask {
  DateTime? _startRecordingTime, _endRecordingTime;
  XFile? _file;
  MediaType _mediaType = MediaType.image;

  @override
  bool get hasWidget => true;

  @override
  Widget? get widget => CameraTaskPage(mediaUserTask: this);

  VideoUserTask(super.executor);

  /// Callback when a picture is captured.
  void onPictureCapture(XFile image) {
    debug('$runtimeType - onPictureCapture(), media: ${image.path}');
    _file = image;
    _mediaType = MediaType.image;
    _startRecordingTime = DateTime.now();
    _endRecordingTime = DateTime.now();

    backgroundTaskExecutor.start();
  }

  /// Callback when video recording is started.
  void onRecordStart() {
    debug('$runtimeType - onRecordStart()');
    _startRecordingTime = DateTime.now();
    backgroundTaskExecutor.start();
  }

  /// Callback when video recording is stopped.
  void onRecordStop(XFile media) {
    debug('$runtimeType - onRecordStop(), media: ${media.path}');
    _file = media;
    _endRecordingTime = DateTime.now();
    _mediaType = MediaType.video;
  }

  /// Callback when the recorded image/video is to be "saved", i.e. committed to
  /// the data stream.
  void onSave() {
    MediaData? media;
    backgroundTaskExecutor.stop();
    if (_file != null) {
      // create the media measurement ...
      media = switch (_mediaType) {
        MediaType.image => ImageMedia(
            filename: _file!.path, startRecordingTime: _startRecordingTime!, endRecordingTime: _endRecordingTime)
          ..filename = _file!.path.split("/").last
          ..path = _file!.path,
        MediaType.video => VideoMedia(
            filename: _file!.path, startRecordingTime: _startRecordingTime!, endRecordingTime: _endRecordingTime)
          ..filename = _file!.path.split("/").last
          ..path = _file!.path,
        _ => null,
      };

      // ... and add it to the sensing controller
      if (media != null) bloc.addMeasurement(Measurement.fromData(media));
    }
    super.onDone(result: media);
  }
}
