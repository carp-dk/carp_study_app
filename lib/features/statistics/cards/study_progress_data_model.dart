part of carp_study_app;

/// View model for the [StudyProgressCardWidget] and [TaskCompletionCard].
class StudyProgressCardViewModel extends ViewModel {
  /// How many days of task history the [TaskCompletionCard] shows.
  static const int completionHistoryDays = 14;

  final Map<String, int> _progressTable = {};

  /// The number of tasks completed on each of the last [completionHistoryDays]
  /// days, oldest first - a zero for days with nothing done.
  List<int> get recentCompletions => completionsPerDay(
    AppTaskController().userTaskQueue.where((task) => task.state == UserTaskState.done).map((task) => task.doneTime),
  );

  /// Bucket [doneTimes] into one count per day for the [completionHistoryDays]
  /// days ending on [today], oldest first. Null times and anything older than
  /// the window are ignored.
  static List<int> completionsPerDay(Iterable<DateTime?> doneTimes, {DateTime? today}) {
    final done = <String, int>{};
    for (final time in doneTimes) {
      if (time == null) continue;
      final day = _dayKey(time.toLocal());
      done[day] = (done[day] ?? 0) + 1;
    }

    final lastDay = today ?? DateTime.now();
    return List.generate(
      completionHistoryDays,
      (index) => done[_dayKey(lastDay.subtract(Duration(days: completionHistoryDays - 1 - index)))] ?? 0,
    );
  }

  static String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

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
  Future<void> init(SmartphoneStudyController ctrl) async {
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
