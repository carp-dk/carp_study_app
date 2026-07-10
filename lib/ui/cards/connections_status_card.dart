part of carp_study_app;

/// Home card summarising the connection state of all data sources (hardware
/// devices + online services, excluding the phone itself).
///
/// The connection data comes from [HomePageViewModel]; this widget only maps it
/// to visuals and owns the expand/collapse toggle.
// ponytail: labels hardcoded EN to match the rest of the static home page; i18n later.
class ConnectionsStatusCard extends StatefulWidget {
  final HomePageViewModel model;
  const ConnectionsStatusCard({required this.model, super.key});

  @override
  State<ConnectionsStatusCard> createState() => _ConnectionsStatusCardState();
}

class _ConnectionsStatusCardState extends State<ConnectionsStatusCard> {
  static const _green = Color(0xFF22C55E);
  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFF43F5E);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CarpColors>()!;
    final locale = RPLocalizations.of(context)!;
    final model = widget.model;
    final total = model.totalSourceCount;
    final active = model.activeSourceCount;

    final (accent, icon, title, badge) = switch (model.connectionState) {
      HomeConnectionState.all => (_green, Icons.sync, 'Connected & sending data', 'LIVE'),
      HomeConnectionState.partial => (_amber, Icons.sync_problem, 'Partially connected', 'ACTION'),
      HomeConnectionState.none => (_rose, Icons.sync_disabled, 'No devices connected', 'SETUP'),
    };

    final sources = switch (model.connectionState) {
      HomeConnectionState.all => 'All $total sources active',
      HomeConnectionState.partial => '$active of $total sources active',
      HomeConnectionState.none => 'No sources active',
    };
    final hint = switch (model.connectionState) {
      HomeConnectionState.all => 'tap to view',
      HomeConnectionState.partial => 'tap to fix',
      HomeConnectionState.none => 'tap to set up',
    };

    return StudiesMaterial(
      backgroundColor: colors.grey50!,
      hasBorder: true,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(title, style: fs20fw700.copyWith(color: colors.grey900))),
                            const SizedBox(width: 8),
                            _badge(accent, badge),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$sources • $hint', style: fs14fw600.copyWith(color: colors.grey600)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: colors.grey100, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                      color: colors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _expanded ? _details(context, colors, locale) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, CarpColors colors, RPLocalizations locale) {
    final model = widget.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in model.connectionSources)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: model.isSourceActive(d) ? _green : colors.grey400),
                const SizedBox(width: 8),
                Expanded(child: Text(locale.translate(d.typeName), style: fs16fw400.copyWith(color: colors.grey900))),
                Text(
                  model.isSourceActive(d) ? 'ON' : 'OFF',
                  style: fs14fw600.copyWith(color: model.isSourceActive(d) ? _green : colors.grey500),
                ),
              ],
            ),
          ),
        Divider(height: 1, color: colors.grey200),
        InkWell(
          onTap: () => context.go(DeviceListPage.route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Manage in Connections', style: fs16fw600.copyWith(color: colors.primary)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: colors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(Color accent, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: accent),
          const SizedBox(width: 5),
          Text(label, style: fs12fw600.copyWith(color: accent)),
        ],
      ),
    );
  }
}
