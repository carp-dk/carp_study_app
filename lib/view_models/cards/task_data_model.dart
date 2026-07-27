part of carp_study_app;

/// The data model for the the different task card widgets, like TaskCardWidget]
/// and [MediaCardWidget].
/// Keeps track on the number of different tasks done ordered by their task title.
class TaskCardViewModel extends ViewModel {
  String taskType;

  /// Create a data model for a card showing the number of tasks done of
  /// type [taskType] (e.g., at survey task).
  TaskCardViewModel(this.taskType) : super();

  /// A map of task count indexed by the task title.
  ///
  ///   (task.title,count)
  ///
  Map<String, int> get tasksTable {
    Map<String, int> tasksTable = {};

    AppTaskController().userTaskQueue
        .where((task) => task.state == UserTaskState.done && task.type == taskType)
        .forEach((task) {
          if (!tasksTable.containsKey(task.title)) tasksTable[task.title] = 0;
          tasksTable[task.title] = tasksTable[task.title]! + 1;
        });
    return tasksTable;
  }

  /// The total number of tasks done of type [taskType].
  int get tasksDone => AppTaskController().userTaskQueue
      .where((task) => task.state == UserTaskState.done && task.type == taskType)
      .length;

  /// The list of [TaskCount]s done.
  List<TaskCount> get taskCount {
    // sort them first
    var mapEntries = tasksTable.entries.toList()..sort((b, a) => a.value.compareTo(b.value));
    Map<String, int> sortedTasksTable = {}..addEntries(mapEntries);

    // and map to the [TaskCount] model
    List<TaskCount> tasksList = sortedTasksTable.entries.map((entry) => TaskCount(entry.key, entry.value)).toList();

    return tasksList;
  }
}

class TaskCount {
  final String title;
  final int size;
  TaskCount(this.title, this.size);
}
