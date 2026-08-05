part of carp_study_app;

/// The "Tasks" tab (design 2.0): a segmented Pending / Completed switch over a
/// list of task cards.
class TaskListPage extends StatefulWidget {
  static const String route = '/tasks';
  final TaskListPageViewModel model;
  const TaskListPage({super.key, required this.model});

  @override
  TaskListPageState createState() => TaskListPageState();
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
          backgroundColor: Theme.of(context).extension<CarpColors>()!.grey900,
          content: Text(RPLocalizations.of(context)!.translate('Done!')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    final colors = Theme.of(context).extension<CarpColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: const CarpAppBar(hasProfileIcon: true),
            ),
            CarpPageTitle(locale.translate('pages.task_list.title')),
            Expanded(
              child: StreamBuilder<UserTask>(
                stream: widget.model.userTaskEvents,
                builder: (context, snapshot) {
                  final pending = widget.model.pendingTasks;
                  final completed = widget.model.completedTasks;
                  final showing = _tabController.index == 0 ? pending : completed;
                  final showParticipantData = _tabController.index == 0 && widget.model.showParticipantDataCard;

                  return Column(
                    children: [
                      _segmentedControl(colors, locale, pending.length, completed.length),
                      Expanded(
                        child: showing.isEmpty && !showParticipantData
                            ? _emptyState(colors, locale)
                            : ListView(
                                padding: const EdgeInsets.only(bottom: 16),
                                children: [
                                  if (showParticipantData) _participantDataCard(colors),
                                  for (final task in showing) _taskCard(context, colors, task),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The Pending / Completed switch: a pill track with the selected segment
  /// lifted out in white.
  Widget _segmentedControl(CarpColors colors, RPLocalizations locale, int pending, int completed) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.grey200, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(8),
        indicator: ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: colors.white,
          shadows: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        tabs: [
          _tab(colors, locale.translate('pages.task_list.pending'), pending, 0),
          _tab(colors, locale.translate('pages.task_list.completed'), completed, 1),
        ],
      ),
    ),
  );

  /// One segment of the Pending / Completed switch, with a count badge.
  Widget _tab(CarpColors colors, String label, int count, int index) {
    final selected = _tabController.index == index;
    return Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: selected ? colors.grey900 : colors.grey600),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : colors.grey300,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text('$count', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: selected ? Theme.of(context).colorScheme.primary : colors.grey600)),
          ),
        ],
      ),
    );
  }

  /// A task card, in either tab - the state decides the accent colour, the
  /// badge and which meta chips are shown.
  Widget _taskCard(BuildContext context, CarpColors colors, UserTask userTask) {
    final locale = RPLocalizations.of(context)!;
    final done = userTask.state == UserTaskState.done;
    final expired = userTask.state == UserTaskState.expired;
    final accent = done
        ? Theme.of(context).extension<CarpColors>()!.taskCompleted
        : expired
        ? colors.grey500
        : taskTypeColors[userTask.type] ?? Theme.of(context).colorScheme.primary;
    final description = locale.translate(userTask.description);
    final (expiry, urgent) = _expiry(locale, userTask);

    return _card(
      colors,
      onTap: done || expired
          ? null
          : () {
              if (widget.model.startUserTask(userTask)) context.push('/task/${userTask.id}');
            },
      badge: _badge(accent, child: _taskBadgeIcon(colors, userTask, accent)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                userTask.type[0].toUpperCase() + userTask.type.substring(1),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: accent),
              ),
            ),
            if (!done && !expired && expiry.isNotEmpty)
              _chip(colors, Icons.alarm, expiry, urgent ? colors.warning : colors.grey500, filled: urgent),
            if (done && userTask.doneTime != null)
              Text(
                DateFormat('MMM d, yyyy').format(userTask.doneTime!),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colors.grey500),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(locale.translate(userTask.title), style: Theme.of(context).textTheme.labelLarge!.copyWith(color: colors.grey900)),
        if (!done && !expired && description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colors.grey600),
          ),
        ],
        if (!done && !expired) ...[
          const SizedBox(height: 10),
          _chip(colors, Icons.schedule, _estimatedTime(locale, userTask), colors.grey500),
        ],
      ],
    );
  }

  Widget _participantDataCard(CarpColors colors) {
    final accent = taskTypeColors["ExpectedParticipantData"]!;
    return _card(
      colors,
      onTap: () => context.push(ParticipantDataPage.route),
      badge: _badge(accent, child: Icon(taskTypeIcons["ExpectedParticipantData"]!.icon, color: accent, size: 20)),
      children: [
        Text("Input Data", style: Theme.of(context).textTheme.labelSmall!.copyWith(color: accent)),
        const SizedBox(height: 4),
        Text("Participant Data", style: Theme.of(context).textTheme.labelLarge!.copyWith(color: colors.grey900)),
        const SizedBox(height: 4),
        Text(
          "Fill in the required participant data to continue with the study.",
          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colors.grey600),
        ),
      ],
    );
  }

  /// The shared card shell: badge on the left, content column, chevron when
  /// the card leads somewhere.
  Widget _card(CarpColors colors, {required Widget badge, required List<Widget> children, VoidCallback? onTap}) {
    return StudiesMaterial(
      backgroundColor: colors.grey50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: colors.grey400),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Rounded-square badge: the accent colour tinted, with the icon on top.
  Widget _badge(Color accent, {required Widget child}) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
    child: child,
  );

  /// A small icon + label chip, outlined by default and tinted when [filled].
  Widget _chip(CarpColors colors, IconData icon, String label, Color color, {bool filled = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: filled ? 8 : 0, vertical: filled ? 4 : 0),
    decoration: filled
        ? BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100))
        : null,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color)),
      ],
    ),
  );

  /// The icon for [userTask], or a spinner while it is running.
  Widget _taskBadgeIcon(CarpColors colors, UserTask userTask, Color accent) {
    return StreamBuilder(
      stream: userTask.stateEvents,
      initialData: userTask.state,
      builder: (context, snapshot) {
        if (userTask.state == UserTaskState.started) {
          return SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: accent));
        }
        final icon = taskTypeIcons[userTask.type]?.icon ?? Icons.assignment;
        return Icon(userTask.state == UserTaskState.done ? Icons.check : icon, color: accent, size: 20);
      },
    );
  }

  /// How long [userTask] takes, or that it completes on its own.
  String _estimatedTime(RPLocalizations locale, UserTask userTask) => userTask.task.minutesToComplete != null
      ? '${locale.translate('pages.task_list.task.estimated_time')} ${userTask.task.minutesToComplete} min'
      : locale.translate('pages.task_list.task.auto_complete');

  /// The humanized time left on [userTask], and whether that is under a day.
  (String, bool) _expiry(RPLocalizations locale, UserTask userTask) {
    final expiresIn = userTask.expiresIn;
    if (expiresIn == null) return ('', false);
    if (expiresIn.isNegative) {
      userTask.onExpired();
      return ('', false);
    }
    return (expiresIn.humanize(locale), expiresIn.inHours < 24);
  }

  Widget _emptyState(CarpColors colors, RPLocalizations locale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _tabController.index == 0 ? Icons.playlist_add_check : Icons.history,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate("pages.task_list.no_tasks"),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colors.grey600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Map<String, Icon> taskTypeIcons = {
    AppTask.SURVEY_TYPE: const Icon(Icons.workspaces, color: Color(0xff3A82F7)),
    AppTask.COGNITIVE_ASSESSMENT_TYPE: const Icon(Icons.psychology, color: Color(0xffB25FEA)),
    AppTask.AUDIO_TYPE: const Icon(Icons.hearing, color: Color(0xff67CE67)),
    AppTask.VIDEO_TYPE: const Icon(Icons.videocam, color: Color(0xff81CFFA)),
    AppTask.IMAGE_TYPE: const Icon(Icons.image, color: Color(0xffF8D100)),
    AppTask.HEALTH_ASSESSMENT_TYPE: const Icon(Icons.favorite_rounded, color: Color(0xffEB4B62)),
    AppTask.SENSING_TYPE: const Icon(Icons.sensors, color: Color(0xffA1616A)),
    "ExpectedParticipantData": const Icon(Icons.dataset, color: Color(0xffA1616A)),
  };

  static Map<String, Color> taskTypeColors = {
    AppTask.SURVEY_TYPE: Color(0xff3A82F7),
    AppTask.COGNITIVE_ASSESSMENT_TYPE: const Color(0xffB25FEA),
    AppTask.AUDIO_TYPE: Color(0xff67CE67),
    AppTask.VIDEO_TYPE: const Color(0xff81CFFA),
    AppTask.IMAGE_TYPE: const Color(0xffF8D100),
    AppTask.HEALTH_ASSESSMENT_TYPE: Color(0xffEB4B62),
    AppTask.SENSING_TYPE: const Color(0xffA1616A),
    "ExpectedParticipantData": Color(0xffA1616A),
  };

  static Map<String, Icon> measureTypeIcons = {
    DeviceSamplingPackage.FREE_MEMORY: const Icon(Icons.memory, color: Color(0xffDADADA)),
    DeviceSamplingPackage.DEVICE_INFORMATION: const Icon(Icons.phone_android, color: Color(0xffDADADA)),
    DeviceSamplingPackage.BATTERY_STATE: const Icon(Icons.battery_charging_full, color: Color(0xff67CE67)),
    CarpDataTypes.STEP_COUNT: const Icon(Icons.directions_walk, color: Color(0xffB25FEA)),
    SensorSamplingPackage.ACCELERATION: const Icon(Icons.adb, color: Color(0xffDADADA)),
    SensorSamplingPackage.ROTATION: const Icon(Icons.adb, color: Color(0xffDADADA)),
    SensorSamplingPackage.AMBIENT_LIGHT: const Icon(Icons.highlight, color: Color(0xffF8D100)),
    MediaSamplingPackage.AUDIO: const Icon(Icons.mic, color: Color(0xff67CE67)),
    MediaSamplingPackage.NOISE: const Icon(Icons.hearing, color: Color(0xffF8D100)),
    MediaSamplingPackage.VIDEO: const Icon(Icons.videocam, color: Color(0xff81CFFA)),
    MediaSamplingPackage.IMAGE: const Icon(Icons.image, color: Color(0xffF8D100)),
    DeviceSamplingPackage.SCREEN_EVENT: const Icon(Icons.screen_lock_portrait, color: Color(0xffB25FEA)),
    ContextSamplingPackage.LOCATION: const Icon(Icons.location_searching, color: Color(0xff4F6432)),
    ContextSamplingPackage.ACTIVITY: const Icon(Icons.local_fire_department, color: Color(0xffEC6330)),
    ContextSamplingPackage.WEATHER: const Icon(Icons.cloud, color: Color(0xff81CFFA)),
    ContextSamplingPackage.AIR_QUALITY: const Icon(Icons.air, color: Color(0xffB2B2B2)),
    ContextSamplingPackage.GEOFENCE: const Icon(Icons.location_on, color: Color(0xff4F6432)),
    ContextSamplingPackage.MOBILITY: const Icon(Icons.location_on, color: Color(0xffEC6330)),
    SurveySamplingPackage.SURVEY: const Icon(Icons.workspaces, color: Color(0xffEC6330)),
  };

  static Map<UserTaskState, Icon> get taskStateIcon => {
    UserTaskState.initialized: const Icon(Icons.stream, color: Color(0xffF8D100)),
    UserTaskState.enqueued: const Icon(Icons.notifications, color: Color(0xffF8D100)),
    UserTaskState.dequeued: const Icon(Icons.stop, color: Color(0xffF8D100)),
    UserTaskState.started: const Icon(Icons.play_arrow, color: Color(0xffDADADA)),
    UserTaskState.canceled: const Icon(Icons.pause, color: Color(0xffDADADA)),
    UserTaskState.done: const Icon(Icons.check, color: Color(0xff67CE67)),
  };
}
