part of carp_study_app;

/// A view model for the [TaskListPage].
class TaskListPageViewModel extends ViewModel {
  TaskListPageViewModel();

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

  /// The number of days the user has been part of this study.
  ///
  /// This is calculated from the study deployment status creation date from the
  /// [StudyDeploymentStatus].
  /// Returns 0 if the study deployment status is not available.
  int get daysInStudy => (bloc.study.cachedDeploymentStatus != null)
      ? DateTime.now().difference(bloc.study.cachedDeploymentStatus!.createdOn).inDays
      : 0;

  /// The number of tasks completed so far.
  int get taskCompleted => AppTaskController().userTaskQueue.where((task) => task.state == UserTaskState.done).length;
}
