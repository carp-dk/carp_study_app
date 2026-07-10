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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
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
                      child: _statTile(colors, Icons.task_alt, colors.warningColor!, 'Task completed', '${model.taskCompleted}'),
                    ),
                  ],
                ),
              ),
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

  Widget _statTile(CarpColors colors, IconData icon, Color iconColor, String label, String value) {
    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 24),
            Text(label, style: fs14fw600.copyWith(color: colors.grey600)),
            const SizedBox(height: 4),
            Text(value, style: fs30fw800.copyWith(color: colors.grey900)),
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
/// Tapping opens the store; the X dismisses it for this session.
class AppUpdateCard extends StatefulWidget {
  final HomePageViewModel model;
  const AppUpdateCard({required this.model, super.key});

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<AppUpdateCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.model.appUpdateAvailable || _dismissed) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<CarpColors>()!;
    final locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      child: InkWell(
        onTap: widget.model.openAppStore,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colors.primary!.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.info_outline, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locale.translate('pages.about.app_update'),
                  style: fs16fw600.copyWith(color: colors.grey900),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.grey500),
                onPressed: () => setState(() => _dismissed = true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
