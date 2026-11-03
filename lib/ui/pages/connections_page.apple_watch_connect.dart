part of carp_study_app;

/// Step-by-step Apple Watch setup: pair, install CARP on the watch, start it,
/// and see the first data arrive. Each step is checked against the live
/// WatchConnectivity status, so the participant knows it actually works.
class AppleWatchConnectPage extends StatefulWidget {
  final ConnectionViewModel device;
  const AppleWatchConnectPage({super.key, required this.device});

  @override
  State<AppleWatchConnectPage> createState() => _AppleWatchConnectPageState();
}

class _AppleWatchConnectPageState extends State<AppleWatchConnectPage> {
  static const _steps = ['pair', 'install', 'start', 'done'];
  static const _icons = [Icons.watch, Icons.install_mobile, Icons.play_circle_outline, Icons.check_circle_outline];

  late final PageController _pages;
  late int _page;
  late AppleWatchStatus _status;
  StreamSubscription<AppleWatchStatus>? _subscription;

  AppleWatchDeviceManager get _manager => widget.device.deviceManager as AppleWatchDeviceManager;

  bool get _hasData => _status.lastFileTransferAt != null;

  /// Whether each step's requirement is met, in [_steps] order.
  List<bool> get _done => [
    _status.isPaired,
    _status.isWatchAppInstalled,
    // ponytail: isCollectingData resets when the phone app restarts, so data arriving counts too.
    // A watch stopped after a transfer still reads as started; a heartbeat from the watch would fix it.
    _status.isCollectingData || _hasData,
    _hasData,
  ];

  @override
  void initState() {
    super.initState();
    _status = _manager.watchStatus;
    // Resume at the first unmet step - steps unlock in order.
    _page = _done.indexOf(false).clamp(0, _steps.length - 1);
    _pages = PageController(initialPage: _page);
    _subscription = _manager.watchStatusEvents.listen(_onStatus);
    unawaited(_connect());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _pages.dispose();
    super.dispose();
  }

  void _onStatus(AppleWatchStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
    if (status.isAvailable) unawaited(_connect());
  }

  /// Activates WatchConnectivity, so the watch can fetch its settings, and
  /// connects once the watch is paired with CARP installed - before it starts
  /// sending data, so nothing arrives without a listener.
  Future<void> _connect() async {
    if (!_manager.canConnect || _manager.isConnecting) return;
    await _manager.connect();
    if (mounted) setState(() => _status = _manager.watchStatus);
  }

  void _goTo(int page) {
    setState(() => _page = page);
    unawaited(_pages.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut));
  }

  // Undocumented but long-standing scheme for the iPhone Watch app; a no-op if it ever stops working.
  Future<void> _openWatchApp() async {
    try {
      await launchUrl(Uri.parse('itms-watchs://'));
    } catch (error) {
      warning('Could not open the Watch app: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    final last = _page == _steps.length - 1;

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
              child: PageView.builder(
                controller: _pages,
                // Steps unlock in order - only the buttons move between them.
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, i) => _stepPage(locale, i),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? _appleWatchColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _page == 0 ? Navigator.pop(context) : _goTo(_page - 1),
                    child: Text(locale.translate(_page == 0 ? 'cancel' : 'back')),
                  ),
                  FilledButton(
                    onPressed: !_done[_page]
                        ? null
                        : last
                        ? () => Navigator.pop(context)
                        : () => _goTo(_page + 1),
                    child: Text(locale.translate(last ? 'done' : 'next')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepPage(RPLocalizations locale, int i) {
    final theme = Theme.of(context);
    String t(String key, [int? step]) =>
        locale.translate('pages.connections.type.apple_watch.step.${_steps[step ?? i]}.$key');
    Widget check(int step) => _check(_done[step], t(_done[step] ? 'ok' : 'waiting', step));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('${i + 1}/${_steps.length}', style: theme.textTheme.labelLarge!.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(t('title'), style: theme.textTheme.titleLarge!.copyWith(color: Colors.grey.shade900)),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _appleWatchColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(_icons[i], size: 64, color: _appleWatchColor),
          ),
        ),
        const SizedBox(height: 24),
        Text(t('body'), style: theme.textTheme.bodyLarge!.copyWith(height: 1.4)),
        const SizedBox(height: 24),
        // The last page sums up every check; the others show their own.
        if (i == _steps.length - 1)
          for (var j = 0; j < _steps.length; j++) check(j)
        else
          check(i),
        if (i < 2) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openWatchApp,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(locale.translate('pages.connections.type.apple_watch.open_watch_app')),
            ),
          ),
        ],
      ],
    );
  }

  Widget _check(bool ok, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: ok
              ? const Icon(Icons.check_circle, color: _statusSuccess)
              : const Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );
}
