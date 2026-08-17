part of carp_study_app;

class TaskListPage extends StatefulWidget {
  static const String route = '/tasks';
  final TaskListPageViewModel model;
  const TaskListPage({super.key, required this.model});

  @override
  TaskListPageState createState() => TaskListPageState();
}

/// Custom SliverAppBarDelegate class
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class TaskListPageState extends State<TaskListPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.model.addListener(_onModelChanged);
    widget.model.checkParticipantData();

    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (!mounted) return;

    final autoCompleted = widget.model.autoCompletedTask;
    if (autoCompleted != null) {
      widget.model.autoCompletedTaskShown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey.shade700,
          content: Text(RPLocalizations.of(context)!.translate('Done!')),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                child: const CarpAppBar(hasProfileIcon: true),
              ),
              Expanded(
                flex: 4,
                child: StreamBuilder<UserTask>(
                  stream: widget.model.userTaskEvents,
                  builder: (context, snapshot) {
                    if (widget.model.tasks.isEmpty) {
                      return _noTasks(context);
                    } else {
                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  locale.translate('pages.task_list.title'),
                                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Scoreboard showing days in study and tasks completed
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 4, bottom: 6, left: 40, right: 40),
                            sliver: ScoreboardCard(widget.model),
                          ),
                          // Tab holder
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24, left: 64, right: 64),
                            sliver: SliverPersistentHeader(
                              pinned: true,
                              delegate: _SliverAppBarDelegate(
                                TabBar(
                                  controller: _tabController,
                                  labelPadding: const EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
                                  labelColor: Colors.grey.shade900,
                                  unselectedLabelColor: Colors.grey.shade900,
                                  dividerColor: Colors.transparent,
                                  indicator: ShapeDecoration(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    color: Colors.white,
                                  ),
                                  tabs: [
                                    Container(
                                      width: double.infinity,
                                      child: Tab(text: locale.translate('pages.task_list.pending')),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      child: Tab(text: locale.translate('pages.task_list.completed')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.model.showParticipantDataCard)
                            SliverToBoxAdapter(child: _buildParticipantDataCard()),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                              UserTask userTask = widget.model.tasks[index];
                              if (_tabController.index == 0) {
                                if (userTask.availableForUser) {
                                  return _buildAvailableTaskCard(context, userTask);
                                }
                              } else if (_tabController.index == 1) {
                                if (userTask.state == UserTaskState.done || userTask.state == UserTaskState.expired) {
                                  return _buildCompletedTaskCard(context, userTask);
                                }
                              }
                              return const SizedBox.shrink();
                            }, childCount: widget.model.tasks.length),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantDataCard() {
    return GestureDetector(
      child: StudiesMaterial(
        hasBorder: true,
        borderColor: taskTypeColors["ExpectedParticipantData"]!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(2.0), right: Radius.circular(8.0)),
        ),
        backgroundColor: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            taskTypeIcons["ExpectedParticipantData"]!.icon,
                            color: taskTypeColors["ExpectedParticipantData"],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              "Input Data",
                              style: TextStyle(
                                color: taskTypeColors["ExpectedParticipantData"],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Participant Data",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                            const SizedBox(height: 4.0),
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Text("Fill in the required participant data to continue with the study."),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        context.push(ParticipantDataPage.route);
      },
    );
  }

  Widget _buildAvailableTaskCard(BuildContext context, UserTask userTask) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Center(
      child: StreamBuilder(
        stream: userTask.stateEvents,
        initialData: userTask.state,
        builder: (context, snapshot) => GestureDetector(
          // Ignore taps while the task is running - starting it again is a
          // no-op, but a tap on a task with its own page would push that page
          // a second time.
          onTap: userTask.state == UserTaskState.started
              ? null
              : () {
                  if (widget.model.startUserTask(userTask)) {
                    context.push('/task/${userTask.id}');
                  }
                },
          child: StudiesMaterial(
            hasBorder: true,
            borderColor: taskTypeColors[userTask.type]!,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(2.0), right: Radius.circular(8.0)),
            ),
            backgroundColor: userTask.expiresIn != null && userTask.expiresIn!.inHours < 24
                ? CACHET.TASK_TO_EXPIRE_BACKGROUND
                : Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 12.0), // Space between line and content
                    Expanded(
                      // Allows the content to take remaining space
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (userTask.state == UserTaskState.started) CircularProgressIndicator(),
                              if (userTask.state != UserTaskState.started) _taskTypeIcon(userTask),
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  userTask.type[0].toUpperCase() + userTask.type.substring(1),
                                  style: TextStyle(color: taskTypeColors[userTask.type], fontWeight: FontWeight.bold),
                                ),
                              ),
                              Spacer(),
                              if (_timeRemainingSubtitle(userTask).isNotEmpty)
                                Icon(
                                  Icons.alarm,
                                  color: userTask.expiresIn != null && userTask.expiresIn!.inHours < 24
                                      ? Colors.orange.shade500
                                      : Colors.grey,
                                ),
                              const SizedBox(width: 4.0),
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Text(
                                  _timeRemainingSubtitle(userTask),
                                  style: TextStyle(
                                    color: userTask.expiresIn != null && userTask.expiresIn!.inHours < 24
                                        ? Colors.orange.shade500
                                        : Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locale.translate(userTask.title),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                ),
                                const SizedBox(height: 4.0),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Text(locale.translate(userTask.description)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 20),
                                        child: Text(
                                          _estimatedTimeSubtitle(userTask),
                                          style: TextStyle(color: Colors.grey, fontSize: 12.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get an icon for the [userTask] based on its type. If there is no icon for
  /// the type, use the 1st measure in the task as an icon. If there is no
  /// icon for the measure, use a default icon.
  Widget _taskTypeIcon(UserTask userTask) {
    Icon originalIcon = taskTypeIcons[userTask.type] as Icon;
    return StreamBuilder(
      stream: userTask.stateEvents,
      initialData: UserTaskState.enqueued,
      builder: (context, snapshot) {
        if (taskTypeIcons[userTask.type] != null && userTask.availableForUser) {
          return originalIcon;
        } else if (taskTypeIcons[userTask.type] != null && userTask.state == UserTaskState.started) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(child: CircularProgressIndicator(strokeWidth: 3), height: 14, width: 14),
          );
        } else if (taskTypeIcons[userTask.type] != null && userTask.state == UserTaskState.done) {
          return Icon(originalIcon.icon, color: CACHET.TASK_COMPLETED_BLUE);
        } else {
          return Icon(originalIcon.icon, color: Colors.grey.shade600);
        }
      },
    );
  }

  String _estimatedTimeSubtitle(UserTask userTask) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    String subtitle = (userTask.task.minutesToComplete != null)
        ? '${locale.translate('pages.task_list.task.estimated_time')} ${userTask.task.minutesToComplete} min'
        : locale.translate('pages.task_list.task.auto_complete');

    if (userTask.expiresIn != null) {
      if (userTask.expiresIn!.isNegative) {
        userTask.onExpired();
      }
    }

    return subtitle.isEmpty ? locale.translate(userTask.description) : subtitle;
  }

  String _timeRemainingSubtitle(UserTask userTask) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    String humanizedTimeRemaining = "";
    if (userTask.expiresIn != null) {
      if (userTask.expiresIn!.isNegative) {
        userTask.onExpired();
      }

      humanizedTimeRemaining = userTask.expiresIn!.humanize(locale);
    }

    return humanizedTimeRemaining.isNotEmpty ? humanizedTimeRemaining : "";
  }

  Widget _buildCompletedTaskCard(BuildContext context, UserTask userTask) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Center(
      child: GestureDetector(
        child: StudiesMaterial(
          backgroundColor: Colors.grey.shade50,
          hasBorder: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(2.0), right: Radius.circular(8.0)),
          ),
          borderColor: (userTask.state == UserTaskState.done) ? CACHET.TASK_COMPLETED_BLUE : CACHET.GREY_6,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 12.0), // Space between line and content
                  Expanded(
                    // Allows the content to take remaining space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _taskTypeIcon(userTask),
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                userTask.type,
                                style: TextStyle(
                                  color: (userTask.state == UserTaskState.done)
                                      ? CACHET.TASK_COMPLETED_BLUE
                                      : CACHET.GREY_6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Spacer(),
                            Text(
                              userTask.doneTime != null
                                  ? DateFormat('MMMM dd yyyy').format(userTask.doneTime!)
                                  : 'Done time null',
                              style: TextStyle(
                                color: userTask.expiresIn != null && userTask.expiresIn!.inHours < 24
                                    ? Colors.orange.shade500
                                    : Colors.grey,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.translate(userTask.title),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noTasks(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Ink(
          width: 60,
          height: 60,
          decoration: const ShapeDecoration(color: CACHET.GREY_1, shape: CircleBorder()),
          child: const Icon(Icons.playlist_add_check, color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(locale.translate("pages.task_list.no_tasks"), style: Theme.of(context).textTheme.labelLarge!, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  static Map<String, Icon> taskTypeIcons = {
    AppTask.SURVEY_TYPE: const Icon(Icons.workspaces, color: CACHET.TASK_BLUE),
    AppTask.COGNITIVE_ASSESSMENT_TYPE: const Icon(Icons.psychology, color: CACHET.LIGHT_PURPLE),
    AppTask.AUDIO_TYPE: const Icon(Icons.hearing, color: CACHET.GREEN),
    AppTask.VIDEO_TYPE: const Icon(Icons.videocam, color: CACHET.LIGHT_BLUE),
    AppTask.IMAGE_TYPE: const Icon(Icons.image, color: CACHET.YELLOW),
    AppTask.HEALTH_ASSESSMENT_TYPE: const Icon(Icons.favorite_rounded, color: CACHET.RED_1),
    AppTask.SENSING_TYPE: const Icon(Icons.sensors, color: CACHET.LIGHT_BROWN),
    "ExpectedParticipantData": const Icon(Icons.dataset, color: CACHET.TASK_INPUT_DATA),
  };

  static Map<String, Color> taskTypeColors = {
    AppTask.SURVEY_TYPE: CACHET.TASK_BLUE,
    AppTask.COGNITIVE_ASSESSMENT_TYPE: CACHET.LIGHT_PURPLE,
    AppTask.AUDIO_TYPE: CACHET.GREEN,
    AppTask.VIDEO_TYPE: CACHET.LIGHT_BLUE,
    AppTask.IMAGE_TYPE: CACHET.YELLOW,
    AppTask.HEALTH_ASSESSMENT_TYPE: CACHET.RED_1,
    AppTask.SENSING_TYPE: CACHET.LIGHT_BROWN,
    "ExpectedParticipantData": CACHET.TASK_INPUT_DATA,
  };

  static Map<String, Icon> measureTypeIcons = {
    DeviceSamplingPackage.FREE_MEMORY: const Icon(Icons.memory, color: CACHET.GREY_4),
    DeviceSamplingPackage.DEVICE_INFORMATION: const Icon(Icons.phone_android, color: CACHET.GREY_4),
    DeviceSamplingPackage.BATTERY_STATE: const Icon(Icons.battery_charging_full, color: CACHET.GREEN),
    CarpDataTypes.STEP_COUNT: const Icon(Icons.directions_walk, color: CACHET.LIGHT_PURPLE),
    SensorSamplingPackage.ACCELERATION: const Icon(Icons.adb, color: CACHET.GREY_4),
    SensorSamplingPackage.ROTATION: const Icon(Icons.adb, color: CACHET.GREY_4),
    SensorSamplingPackage.AMBIENT_LIGHT: const Icon(Icons.highlight, color: CACHET.YELLOW),
    MediaSamplingPackage.AUDIO: const Icon(Icons.mic, color: CACHET.GREEN),
    MediaSamplingPackage.NOISE: const Icon(Icons.hearing, color: CACHET.YELLOW),
    MediaSamplingPackage.VIDEO: const Icon(Icons.videocam, color: CACHET.LIGHT_BLUE),
    MediaSamplingPackage.IMAGE: const Icon(Icons.image, color: CACHET.YELLOW),
    DeviceSamplingPackage.SCREEN_EVENT: const Icon(Icons.screen_lock_portrait, color: CACHET.LIGHT_PURPLE),
    ContextSamplingPackage.LOCATION: const Icon(Icons.location_searching, color: CACHET.CYAN),
    ContextSamplingPackage.ACTIVITY: const Icon(Icons.local_fire_department, color: CACHET.ORANGE),
    ContextSamplingPackage.WEATHER: const Icon(Icons.cloud, color: CACHET.LIGHT_BLUE),
    ContextSamplingPackage.AIR_QUALITY: const Icon(Icons.air, color: CACHET.GREY_3),
    ContextSamplingPackage.GEOFENCE: const Icon(Icons.location_on, color: CACHET.CYAN),
    ContextSamplingPackage.MOBILITY: const Icon(Icons.location_on, color: CACHET.ORANGE),
    SurveySamplingPackage.SURVEY: const Icon(Icons.workspaces, color: CACHET.ORANGE),
  };

  static Map<UserTaskState, Icon> get taskStateIcon => {
    UserTaskState.initialized: const Icon(Icons.stream, color: CACHET.YELLOW),
    UserTaskState.enqueued: const Icon(Icons.notifications, color: CACHET.YELLOW),
    UserTaskState.dequeued: const Icon(Icons.stop, color: CACHET.YELLOW),
    UserTaskState.started: const Icon(Icons.play_arrow, color: CACHET.GREY_4),
    UserTaskState.canceled: const Icon(Icons.pause, color: CACHET.GREY_4),
    UserTaskState.done: const Icon(Icons.check, color: CACHET.GREEN),
  };
}
