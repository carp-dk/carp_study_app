part of carp_study_app;

/// View model for the [StudyProgressCardWidget].
class StudyProgressCardViewModel extends ViewModel {
  final Map<String, int> _progressTable = {};

  /// A stream of [UserTask]s as they are generated.
  Stream<UserTask> get userTaskEvents => AppTaskController().userTaskEvents;

  /// The number of tasks completed so far.
  int get taskCompleted => AppTaskController().taskCompleted;

  /// The number of tasks expired so far.
  int get taskExpired => AppTaskController().taskExpired;

  /// The number of tasks pending so far.
  int get taskPending => AppTaskController().taskPending;

  /// A table with sampling size of each measure type
  Map<String, int> get progressTable => _progressTable;

  /// The list of measures
  List<StudyProgress> get progress =>
      _progressTable.entries.map((entry) => StudyProgress(entry.key, entry.value)).toList();

  StudyProgressCardViewModel() : super();

  @override
  Future<void> init(SmartphoneDeploymentController ctrl) async {
    super.init(ctrl);
    updateProgress();
  }

  @override
  String toString() {
    String str = 'STUDY PROGRESS\t| #\n';
    _progressTable.forEach((type, no) => str += '$type\t| $no\n');
    return str;
  }

  void updateProgress() {
    _progressTable['completed'] = taskCompleted;
    _progressTable['pending'] = taskPending;
    _progressTable['expired'] = taskExpired;
  }
}

class StudyProgress {
  final String state;
  final int value;
  StudyProgress(this.state, this.value);
}
