part of carp_study_app;

/// The redesigned home page (design 2.0) - the landing tab of the app shell.
class HomePage extends StatelessWidget {
  static const String route = '/home';
  final HomePageViewModel model;
  const HomePage({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              if (!model.isLoaded)
                _skeleton()
              else ...[
                AppUpdateCard(model: model),
                StudyAboutCard(model: model),
                CarpSectionTitle('Connections'),
                ConnectionsStatusCard(model: model),
                CarpSectionTitle('Your progress'),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _activeDaysTile(context)),
                      Expanded(child: _taskStatusTile(context)),
                    ],
                  ),
                ),
                if (model.messages.isNotEmpty) ...[
                  CarpSectionTitle('Feeds'),
                  for (final message in model.messages) _feedCard(context, message),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer placeholders mirroring the page layout (about card, connections,
  /// progress tiles, feeds), shown until the study is loaded.
  Widget _skeleton() {
    Widget box(double height, {EdgeInsetsGeometry? margin}) => Container(
      height: height,
      margin: margin ?? const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
    );
    Widget bar() => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 18,
        width: 120,
        margin: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      ),
    );

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          box(195),
          bar(),
          box(88),
          bar(),
          Row(
            children: [
              Expanded(child: box(180, margin: const EdgeInsets.only(left: 16, right: 6, bottom: 16))),
              Expanded(child: box(180, margin: const EdgeInsets.only(left: 6, right: 16, bottom: 16))),
            ],
          ),
          bar(),
          box(140),
          box(140),
        ],
      ),
    );
  }

  /// "Active Days in Study" tile: total active days, a dot per day for the
  /// last 7 days (filled if at least one task was done), and a stats link.
  Widget _activeDaysTile(BuildContext context) {
    return _statTile(
      context,
      icon: Icons.calendar_today_outlined,
      iconColor: Theme.of(context).colorScheme.primary,
      label: 'Active Days in Study',
      value: Text('${model.activeDaysInStudy}', style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.grey.shade900, fontSize: 28)),
      footer: Row(
        children: [
          for (final active in model.lastWeekActivity)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Theme.of(context).colorScheme.primary : null,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
            ),
        ],
      ),
      linkLabel: 'View Statistics',
      onLink: () => context.go(StatisticsPage.route),
      margin: const EdgeInsets.only(left: 16, right: 6, bottom: 16),
    );
  }

  /// "Task status" tile: completed and pending counts and a tasks link.
  Widget _taskStatusTile(BuildContext context) {
    Widget count(int n, String label) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$n'.padLeft(2, '0'), style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.grey.shade900, fontSize: 28)),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.grey.shade600)),
        ),
      ],
    );
    return _statTile(
      context,
      icon: Icons.task_alt,
      iconColor: const Color(0xffF57C00),
      label: 'Task status',
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [count(model.taskCompleted, 'Completed'), count(model.taskPending, 'Pending')],
      ),
      linkLabel: 'Complete Tasks',
      onLink: () => context.go(TaskListPage.route),
      margin: const EdgeInsets.only(left: 6, right: 16, bottom: 16),
    );
  }

  // Shared stat tile chrome: label + icon badge on top, main content, optional
  // footer row, and a link at the bottom.
  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget value,
    Widget? footer,
    required String linkLabel,
    required VoidCallback onLink,
    required EdgeInsetsGeometry margin,
  }) {
    return StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.grey.shade600)),
                ),
                _iconBadge(icon, iconColor),
              ],
            ),
            const SizedBox(height: 8),
            value,
            if (footer != null) ...[const SizedBox(height: 8), footer],
            // Push the link to the card bottom so both tiles' links align.
            const Spacer(),
            const SizedBox(height: 8),
            InkWell(
              onTap: onLink,
              child: Text(
                linkLabel,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A message (announcement / news / article) from the backend, tappable to
  /// open its details page.
  Widget _feedCard(BuildContext context, Message message) {
    final locale = RPLocalizations.of(context)!;
    final subTitle = message.subTitle ?? '';
    final body = message.message ?? '';

    return StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
      child: InkWell(
        onTap: () => context.push('${MessageDetailsPage.route}/${message.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      locale.translate(message.title ?? ''),
                      style: Theme.of(context).textTheme.titleMedium!,
                    ),
                  ),
                  _iconBadge(message.type.icon, Theme.of(context).colorScheme.primary),
                ],
              ),
              if (subTitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(locale.translate(subTitle), style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.grey.shade600)),
              ],
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  locale.translate(body),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(timeago.format(message.timestamp.toLocal()), style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rounded-square badge: tinted background with the icon in the accent color.
  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
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
    final locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(locale.translate('pages.about.app_update'), style: Theme.of(context).textTheme.labelMedium!),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: model.openAppStore,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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

/// Gradient home card with the study title, its deployment status as a bubble,
/// a short description (max 2 lines), and a link to the full about page.
class StudyAboutCard extends StatelessWidget {
  final HomePageViewModel model;
  const StudyAboutCard({required this.model, super.key});

  static const Map<StudyDeploymentStatusTypes, (Color, String)> _status = {
    StudyDeploymentStatusTypes.Invited: (Color(0xFFF59E0B), 'INVITED'),
    StudyDeploymentStatusTypes.DeployingDevices: (Color(0xFFF59E0B), 'DEPLOYING'),
    StudyDeploymentStatusTypes.Running: (Color(0xFF22C55E), 'RUNNING'),
    StudyDeploymentStatusTypes.Stopped: (Color(0xFFF43F5E), 'STOPPED'),
  };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(primary, Colors.white, 0.3)!, primary],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The status arrives async after the card is first shown; keep the
            // bubble slot occupied (invisible placeholder) so the card height
            // doesn't jump when it lands.
            Visibility(
              visible: model.deploymentStatus != null,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Row(children: [_statusBubble(context, model.deploymentStatus ?? StudyDeploymentStatusTypes.Running)]),
            ),
            const SizedBox(height: 8),
            Text(locale.translate(model.studyTitle), style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              locale.translate(model.studyDescription),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => context.push(StudyAboutPage.route),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'About the study',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Transparent pill with the status dot and label in white.
  Widget _statusBubble(BuildContext context, StudyDeploymentStatusTypes status) {
    final (dot, label) = _status[status] ?? (const Color(0xFFF43F5E), '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: dot),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
