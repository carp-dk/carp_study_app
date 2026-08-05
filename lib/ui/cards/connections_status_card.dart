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
    final locale = RPLocalizations.of(context)!;
    final model = widget.model;
    final total = model.totalSourceCount;
    final active = model.activeSourceCount;

    final (accent, icon, title) = switch (model.connectionState) {
      HomeConnectionState.all => (_green, Icons.sync, 'Connected & sending data'),
      HomeConnectionState.partial => (_amber, Icons.sync_problem, 'Partially connected'),
      HomeConnectionState.none => (_rose, Icons.sync_disabled, 'No devices connected'),
    };

    final sources = switch (model.connectionState) {
      HomeConnectionState.all => 'All $total sources active',
      HomeConnectionState.partial => '$active sources active · ${total - active} inactive',
      HomeConnectionState.none => 'No sources active',
    };

    return StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(title, style: Theme.of(context).textTheme.titleMedium!),
                        const SizedBox(height: 4),
                        Text(
                          sources,
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4),
                    child: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.chevron_right, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _expanded ? _details(context, locale) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, RPLocalizations locale) {
    final model = widget.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in model.connectionSources)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: model.isSourceActive(d) ? _green : Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(child: Text(locale.translate(d.typeName), style: Theme.of(context).textTheme.bodyLarge!)),
                Text(
                  model.isSourceActive(d) ? 'ON' : 'OFF',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(color: model.isSourceActive(d) ? _green : Colors.grey.shade500),
                ),
              ],
            ),
          ),
        Divider(height: 1, color: Colors.grey.shade200),
        InkWell(
          onTap: () => context.go(DeviceListPage.route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Manage in Connections',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
