part of carp_study_app;

/// Step-by-step Apple Watch setup: pair, install CARP on the watch, open it,
/// and watch the data come in. Each step is checked against the live
/// WatchConnectivity status, so the participant knows it actually works.
class AppleWatchConnectPage extends StatefulWidget {
  final ConnectionViewModel device;
  const AppleWatchConnectPage({super.key, required this.device});

  @override
  State<AppleWatchConnectPage> createState() => _AppleWatchConnectPageState();
}

class _AppleWatchConnectPageState extends State<AppleWatchConnectPage> {
  static const _steps = ['pair', 'install', 'open', 'data'];
  static const _icons = [Icons.watch, Icons.install_mobile, Icons.touch_app_outlined];

  /// A connected watch has nothing left to set up - the page only shows its live state.
  late final bool _statusOnly = _manager.isConnected;
  late final PageController _pages;
  late int _page;
  late AppleWatchStatus _status;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Records received per AWARE table while this page is open.
  final Map<String, int> _counts = {};
  AppleWatchFileTransfer? _transfer;
  Timer? _transferIdle;

  AppleWatchDeviceManager get _manager => widget.device.deviceManager as AppleWatchDeviceManager;

  bool get _hasData => _status.lastFileTransferAt != null || _counts.isNotEmpty;

  /// Whether each step's requirement is met, in [_steps] order.
  /// The watch app only sends data while it is open - that is what "open" checks.
  List<bool> get _done => [_status.isPaired, _status.isWatchAppInstalled, _status.isReachable, _hasData];

  CarpMorphMode get _mode {
    final transfer = _transfer;
    if (transfer != null && transfer.chunkIndex < transfer.totalChunks) return CarpMorphMode.syncing;
    if (!_status.isReachable || !_status.isCollectingData) return CarpMorphMode.away;
    return _counts.isEmpty ? CarpMorphMode.collecting : CarpMorphMode.sent;
  }

  @override
  void initState() {
    super.initState();
    _status = _manager.watchStatus;
    // Resume at the first unmet step - steps unlock in order.
    _page = _statusOnly ? _steps.length - 1 : _done.indexOf(false).clamp(0, _steps.length - 1);
    _pages = PageController(initialPage: _page);
    _subscriptions
      ..add(_manager.watchStatusEvents.listen(_onStatus))
      ..add(_manager.fileTransferEvents.listen(_onTransfer))
      ..add(_manager.records.listen(_onRecords));
    unawaited(_connect());
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _transferIdle?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _onStatus(AppleWatchStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
    if (status.isAvailable) unawaited(_connect());
  }

  void _onTransfer(AppleWatchFileTransfer transfer) {
    if (!mounted) return;
    setState(() => _transfer = transfer);
    // A chunk can get lost on the way - stop showing a sync nothing is coming for.
    _transferIdle?.cancel();
    _transferIdle = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _transfer = null);
    });
  }

  void _onRecords(AppleWatchRecords batch) {
    if (!mounted || batch.records.isEmpty) return;
    setState(() => _counts.update(batch.table, (n) => n + batch.records.length, ifAbsent: () => batch.records.length));
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
            if (_statusOnly)
              Expanded(child: _stepPage(locale, _page))
            else ...[
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
                        color: i == _page ? CarpSphereMorph.red : Colors.grey.shade300,
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
          ],
        ),
      ),
    );
  }

  Widget _stepPage(RPLocalizations locale, int i) {
    final theme = Theme.of(context);
    String t(String key, [int? step]) =>
        locale.translate('pages.connections.type.apple_watch.step.${_steps[step ?? i]}.$key');
    final data = i == _steps.length - 1;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (!_statusOnly) ...[
          Text('${i + 1}/${_steps.length}', style: theme.textTheme.labelLarge!.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
        ],
        Text(t('title'), style: theme.textTheme.titleLarge!.copyWith(color: Colors.grey.shade900)),
        const SizedBox(height: 24),
        if (data) ...[
          _watchScreen(locale),
          const SizedBox(height: 16),
          // What kinds of data arrived, and how much, right under the visual.
          for (final MapEntry(:key, :value) in _counts.entries)
            _count(
              locale.translate('pages.connections.type.apple_watch.data.${key.replaceFirst('ios_watch_', '')}'),
              value,
            ),
          const SizedBox(height: 8),
          // The watch app sends only while open, so say so whenever it is not.
          _check(_status.isReachable, t(_status.isReachable ? 'ok' : 'waiting', 2)),
        ] else
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CarpSphereMorph.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(_icons[i], size: 64, color: CarpSphereMorph.red),
            ),
          ),
        const SizedBox(height: 24),
        Text(t('body'), style: theme.textTheme.bodyLarge!.copyWith(height: 1.4)),
        const SizedBox(height: 24),
        if (!data) _check(_done[i], t(_done[i] ? 'ok' : 'waiting')),
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

  /// The same sphere-to-CARP morph the watch shows, with what it means below.
  Widget _watchScreen(RPLocalizations locale) {
    final transfer = _transfer;
    final total = _counts.values.fold(0, (a, b) => a + b);
    final mode = _mode;
    final label = switch (mode) {
      CarpMorphMode.syncing => locale.translate(
        'pages.connections.type.apple_watch.receiving',
        args: {'percent': (100 * transfer!.chunkIndex / transfer.totalChunks).round()},
      ),
      CarpMorphMode.away => locale.translate(
        'pages.connections.type.apple_watch.${_status.isReachable ? 'stopped' : 'open_to_send'}',
      ),
      CarpMorphMode.collecting => locale.translate('pages.connections.type.apple_watch.waiting_for_data'),
      CarpMorphMode.sent => locale.translate(
        'pages.connections.type.apple_watch.received',
        args: {'count': NumberFormat.decimalPattern().format(total)},
      ),
    };
    return Center(
      child: Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(44)),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 184 / 150,
              child: CarpSphereMorph(
                mode: mode,
                progress: transfer == null ? 0 : transfer.chunkIndex / transfer.totalChunks,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _count(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(NumberFormat.decimalPattern().format(count), style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );

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
