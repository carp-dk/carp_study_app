part of carp_study_app;

/// How to set up the CARP watch app, then connect - the watch talks over
/// WatchConnectivity, so there is no Bluetooth scan like for other devices.
class AppleWatchConnectPage extends StatefulWidget {
  final ConnectionViewModel device;
  const AppleWatchConnectPage({super.key, required this.device});

  @override
  State<AppleWatchConnectPage> createState() => _AppleWatchConnectPageState();
}

class _AppleWatchConnectPageState extends State<AppleWatchConnectPage> {
  bool _connecting = false;

  AppleWatchDeviceManager get _manager => widget.device.deviceManager as AppleWatchDeviceManager;

  Future<void> _connect(RPLocalizations locale) async {
    setState(() => _connecting = true);
    final status = await _manager.connect();
    if (!mounted) return;
    setState(() => _connecting = false);
    if (status == DeviceStatus.connected) return Navigator.pop(context);

    // The plugin tells why: no watch paired, or the CARP watch app is missing.
    final watch = _manager.watchStatus;
    final reason = !watch.isPaired
        ? 'pages.connections.type.apple_watch.not_paired'
        : !watch.isWatchAppInstalled
        ? 'pages.connections.type.apple_watch.not_installed'
        : 'pages.connections.connection.connection_failed.message';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.translate('pages.connections.connection.connection_failed.title')),
        content: Text(locale.translate(reason)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.translate('ok')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    final theme = Theme.of(context);
    final steps = locale
        .translate('pages.connections.type.apple_watch.instructions')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade700,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(
                    locale.translate('pages.connections.connection.step.how_to.title'),
                    style: theme.textTheme.titleMedium!.copyWith(color: Colors.grey.shade900),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _appleWatchColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(Icons.watch, size: 64, color: _appleWatchColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final (i, step) in steps.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 24, child: Text('${i + 1}.', style: theme.textTheme.bodyLarge)),
                          Expanded(child: Text(step.trim(), style: theme.textTheme.bodyLarge!.copyWith(height: 1.3))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.translate('cancel'))),
                  FilledButton(
                    onPressed: _connecting ? null : () => _connect(locale),
                    child: _connecting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(locale.translate('pages.connections.status.action.connect')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
