part of carp_study_app;

/// The redesigned home page (design 2.0) - the landing tab of the app shell.
// ponytail: hardcoded content; wire study title and feeds later.
class HomePage extends StatelessWidget {
  static const String route = '/home';
  final HomePageViewModel model;
  const HomePage({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CarpColors>()!;
    return Scaffold(
      backgroundColor: colors.backgroundGray,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: model,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                child: CarpAppBar(hasProfileIcon: true),
              ),
              const CarpPageTitle('UX Data collection study'),
              AppUpdateCard(model: model),
              ConnectionsStatusCard(model: model),
              StudyStatusCard(model: model),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _statTile(
                        colors,
                        Icons.calendar_today_outlined,
                        colors.primary!,
                        'Days in Study',
                        '${model.daysInStudy}',
                      ),
                    ),
                    Expanded(
                      child: _statTile(
                        colors,
                        Icons.task_alt,
                        colors.warningColor!,
                        'Task completed',
                        '${model.taskCompleted}',
                        total: '${model.taskTotal}',
                      ),
                    ),
                  ],
                ),
              ),
              if (model.surveys.tasksTable.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Completed Surveys', style: fs22fw700.copyWith(color: colors.grey900)),
                ),
                SurveyCard(model.surveys, showTitle: false),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Feeds', style: fs22fw700.copyWith(color: colors.grey900)),
              ),
              _feedCard(colors, 'Connect Polar Strap', "Sync your heart rate sensor for today's session to ensure data accuracy."),
              _feedCard(colors, 'Health Issues', "Sync your heart rate sensor for today's session."),
            ],
          ),
        ),
      ),
    );
  }

  // Compact stat tile: label + icon badge on top, big value (with optional
  // "/ total") below.
  Widget _statTile(CarpColors colors, IconData icon, Color iconColor, String label, String value, {String? total}) {
    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: fs14fw600.copyWith(color: colors.grey600))),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: value,
                style: fs30fw800.copyWith(color: colors.grey900, fontSize: 28),
                children: [
                  if (total != null) TextSpan(text: ' / $total', style: fs14fw600.copyWith(color: colors.grey500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedCard(CarpColors colors, String title, String body) {
    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: fs20fw700.copyWith(color: colors.grey900))),
                _circleIcon(Icons.campaign, colors.primary!),
              ],
            ),
            const SizedBox(height: 4),
            Text('Subtitle', style: fs14fw600.copyWith(color: colors.grey600)),
            const SizedBox(height: 8),
            Text(body, style: fs16fw400.copyWith(color: colors.grey900)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: colors.grey500),
                const SizedBox(width: 4),
                Text('Today', style: fs12fw600.copyWith(color: colors.grey500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 20)),
    );
  }
}

/// Home banner shown only when a newer app version is available in the store.
/// A slim text row with a "Get" button that opens the store.
class AppUpdateCard extends StatelessWidget {
  final HomePageViewModel model;
  const AppUpdateCard({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    if (!model.appUpdateAvailable) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<CarpColors>()!;
    final locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                locale.translate('pages.about.app_update'),
                style: fs14fw600.copyWith(color: colors.grey900),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: model.openAppStore,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Get'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home card showing the deployment status of the study (running, deploying,
/// stopped, ...) with its explanatory message.
class StudyStatusCard extends StatelessWidget {
  final HomePageViewModel model;
  const StudyStatusCard({required this.model, super.key});

  static const Map<StudyDeploymentStatusTypes, Color> _statusColors = {
    StudyDeploymentStatusTypes.Invited: CACHET.DEPLOYMENT_INVITED,
    StudyDeploymentStatusTypes.DeployingDevices: CACHET.DEPLOYMENT_DEPLOYING,
    StudyDeploymentStatusTypes.Running: CACHET.DEPLOYMENT_RUNNING,
    StudyDeploymentStatusTypes.Stopped: CACHET.DEPLOYMENT_STOPPED,
  };

  static const Map<StudyDeploymentStatusTypes, String> _statusLabels = {
    StudyDeploymentStatusTypes.Invited: 'INVITED',
    StudyDeploymentStatusTypes.DeployingDevices: 'DEPLOYING',
    StudyDeploymentStatusTypes.Running: 'RUNNING',
    StudyDeploymentStatusTypes.Stopped: 'STOPPED',
  };

  static const Map<StudyDeploymentStatusTypes, String> _statusMessages = {
    StudyDeploymentStatusTypes.Invited: 'pages.about.status.invited.message',
    StudyDeploymentStatusTypes.DeployingDevices: 'pages.about.status.deploying_devices.message',
    StudyDeploymentStatusTypes.Running: 'pages.about.status.running.message',
    StudyDeploymentStatusTypes.Stopped: 'pages.about.status.stopped.message',
  };

  @override
  Widget build(BuildContext context) {
    final status = model.deploymentStatus;
    if (status == null) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<CarpColors>()!;
    final locale = RPLocalizations.of(context)!;
    final accent = _statusColors[status] ?? colors.grey500!;

    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                CircleAvatar(radius: 12, backgroundColor: accent),
                const SizedBox(height: 4),
                Text(_statusLabels[status] ?? '', style: fs12fw600.copyWith(color: accent)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                locale.translate(_statusMessages[status] ?? ''),
                style: fs14fw600.copyWith(color: colors.grey900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
