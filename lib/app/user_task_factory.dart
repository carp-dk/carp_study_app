import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_study_app/features/connections/health_connect_user_task.dart';
import 'package:carp_study_app/features/tasks/user_tasks.dart';

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
