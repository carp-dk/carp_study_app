part of carp_study_app;

/// A [UserTaskFactory] that can handle the user tasks in this app.
class AppUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [AppTask.AUDIO_TYPE, AppTask.VIDEO_TYPE, AppTask.IMAGE_TYPE, AppTask.HEALTH_ASSESSMENT_TYPE];

  @override
  UserTask create(AppTaskExecutor executor) => switch (executor.task.type) {
    AppTask.AUDIO_TYPE => AudioUserTask(executor),
    AppTask.VIDEO_TYPE => VideoUserTask(executor),
    AppTask.IMAGE_TYPE => VideoUserTask(executor),
    AppTask.HEALTH_ASSESSMENT_TYPE => HealthConnectUserTask(executor),
    _ => BackgroundSensingUserTask(executor),
  };
}
