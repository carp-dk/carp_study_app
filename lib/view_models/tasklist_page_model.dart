part of carp_study_app;

/// A view model for the [TaskListPage].
class TaskListPageViewModel extends ViewModel {
  TaskListPageViewModel({StudyService? studyService}) : _studyService = studyService;

  final StudyService? _studyService;
  StudyService get _study => _studyService ?? bloc.study;

  bool _showParticipantDataCard = false;
  final Map<String, Timer> _autoCompleteTimers = {};
  UserTask? _autoCompletedTask;

  /// Should the card prompting for participant data be shown?
  bool get showParticipantDataCard => _showParticipantDataCard;

  /// The task most recently auto-completed by [startUserTask], if any.
  /// One-shot - the page calls [autoCompletedTaskShown] once it has shown
  /// a confirmation.
  UserTask? get autoCompletedTask => _autoCompletedTask;

  void autoCompletedTaskShown() => _autoCompletedTask = null;

  /// Check whether participant data is still missing, updating
  /// [showParticipantDataCard].
  Future<void> checkParticipantData() async {
    final data = await _study.getParticipantDataListFromDeployment();
    _showParticipantDataCard = data.isEmpty;
    notifyListeners();
  }

  /// Start [userTask], if it is not already started, done, or expired.
  /// Returns true when the task opens its own page. Otherwise the task is a
  /// background sensing task, which auto-completes after 10 seconds - even
  /// if the user navigates away in the meantime.
  bool startUserTask(UserTask userTask) {
    if (userTask.state != UserTaskState.enqueued && userTask.state != UserTaskState.canceled) return false;

    userTask.onStart();
    if (userTask.hasWidget) return true;

    _autoCompleteTimers[userTask.id] = Timer(const Duration(seconds: 10), () {
      _autoCompleteTimers.remove(userTask.id);
      userTask.onDone();
      _autoCompletedTask = userTask;
      notifyListeners();
    });
    return false;
  }

  void _cancelAutoCompleteTimers() {
    for (var timer in _autoCompleteTimers.values) {
      timer.cancel();
    }
    _autoCompleteTimers.clear();
  }

  @override
  void clear() {
    _cancelAutoCompleteTimers();
    _showParticipantDataCard = false;
    _autoCompletedTask = null;
    super.clear();
  }

  @override
  void dispose() {
    _cancelAutoCompleteTimers();
    super.dispose();
  }

  List<UserTask> get tasks {
    var tasks = AppTaskController().userTaskQueue;
    tasks.sort((t1, t2) {
      if (t1.expiresIn != null && t2.expiresIn != null) {
        // sort by expiration date, soonest first
        return t1.expiresIn!.compareTo(t2.expiresIn!);
      } else if (t1.expiresIn != null) {
        // rank tasks without expiration date first
        if (t1.expiresIn! < Duration(hours: 3)) {
          return -1;
        }
        return 1;
      } else if (t2.expiresIn != null) {
        // rank tasks without expiration date first
        if (t2.expiresIn! < Duration(hours: 3)) {
          return 1;
        }
        return -1;
      } else {
        // alphabetically if no expiration date
        return t2.name.compareTo(t1.name);
      }
    });
    return tasks;
  }

  /// A stream of [UserTask]s as they are generated.
  Stream<UserTask> get userTaskEvents => AppTaskController().userTaskEvents;
}
