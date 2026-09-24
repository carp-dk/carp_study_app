part of carp_study_app;

/// Anonymous sign-in: either scan the QR code of a study invitation, or type
/// in the short code printed next to it.
///
/// The camera fills the whole screen and keeps running; the header and the
/// QR/code switch float on top of it, and the code tab is a frosted sheet over
/// the live backdrop. Scans are only acted on while the QR tab is selected.
class CodeSignInPage extends StatefulWidget {
  static const String route = '/login/join';

  final LoginViewModel model;
  const CodeSignInPage({required this.model, super.key});

  @override
  State<CodeSignInPage> createState() => _CodeSignInPageState();
}

class _CodeSignInPageState extends State<CodeSignInPage> {
  final MobileScannerController _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  bool _scanning = true;
  bool _busy = false;
  bool _codeFailed = false;

  /// A failed QR code is ignored for this long, so it is not hammered while
  /// still in front of the camera - but can be retried by just holding it up again.
  static const Duration _retryCooldown = Duration(seconds: 3);
  String? _failedQrCode;
  DateTime _failedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Side of the square scan window, given the camera view's size.
  static double _scanWindowSize(Size size) => size.shortestSide * 0.78;

  @override
  void dispose() {
    _scanner.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _selectTab(bool scanning) {
    if (scanning == _scanning) return;
    setState(() => _scanning = scanning);
    scanning ? _codeFocus.unfocus() : _codeFocus.requestFocus();
  }

  /// Complete the sign-in flow after a successful authentication. `go`
  /// replaces the whole stack, so this page is gone along with the login page.
  Future<void> _onSignedIn() async {
    final invitations = bloc.appViewModel.invitationsListViewModel;
    await invitations.loadInvitations();
    if (!mounted) return;
    context.go(invitations.landingRoute);
  }

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        // The camera must stay full-screen behind the keyboard; the code
        // sheet handles the keyboard inset itself.
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => MobileScanner(
                controller: _scanner,
                onDetect: _onDetect,
                scanWindow: Rect.fromCenter(
                  center: constraints.biggest.center(Offset.zero),
                  width: _scanWindowSize(constraints.biggest),
                  height: _scanWindowSize(constraints.biggest),
                ),
                errorBuilder: (context, error) =>
                    _CameraMessage(icon: Icons.no_photography_outlined, text: error.errorDetails?.message ?? '$error'),
                placeholderBuilder: (context) => const ColoredBox(color: Colors.black),
              ),
            ),
            if (_scanning) _buildScanOverlay(locale),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          locale.translate('pages.login.sign_in.title'),
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
                        ),
                      ),
                      _GlassButton(
                        icon: Icons.close,
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _GlassSwitch(
                      selected: _scanning ? 0 : 1,
                      labels: [
                        locale.translate('pages.login.sign_in.tab.scan'),
                        locale.translate('pages.login.sign_in.tab.code'),
                      ],
                      onSelected: (index) => _selectTab(index == 0),
                    ),
                  ),
                  // The sheet starts right below the header, whatever its height.
                  if (!_scanning) ...[const SizedBox(height: 24), Expanded(child: _buildCodeSheet(locale))],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay(RPLocalizations locale) => LayoutBuilder(
    builder: (context, constraints) {
      final size = _scanWindowSize(constraints.biggest);
      final window = BorderRadius.circular(28);
      return Stack(
        fit: StackFit.expand,
        children: [
          // Dim everything but the scan window.
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.transparent),
                Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: window),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: _ScanFrame(size: size, radius: window, busy: _busy),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      locale.translate('pages.login.sign_in.scan_hint'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder(
                      valueListenable: _scanner,
                      builder: (context, state, _) => _buildZoomSlider(state.zoomScale),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildZoomSlider(double zoom) => Row(
    children: [
      const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
          ),
          child: Slider(value: zoom.clamp(0, 1), onChanged: _scanner.setZoomScale),
        ),
      ),
      const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
    ],
  );

  /// Frosted sheet with the code input; the button sits at the bottom, above
  /// the keyboard and home indicator, and the content scrolls if space is short.
  Widget _buildCodeSheet(RPLocalizations locale) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.94),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            max(MediaQuery.viewInsetsOf(context).bottom, MediaQuery.paddingOf(context).bottom) + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        locale.translate('pages.login.sign_in.code_hint'),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: CodeInput(
                          controller: _code,
                          focusNode: _codeFocus,
                          enabled: !_busy,
                          hasError: _codeFailed,
                          onChanged: () => setState(() => _codeFailed = false),
                          onCompleted: _signInWithCode,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_codeFailed)
                        Text(
                          locale.translate('pages.login.sign_in.code_invalid'),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                ),
                onPressed: _busy || _code.text.length < LoginViewModel.codeLength ? null : _signInWithCode,
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(locale.translate('pages.login.login')),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _signInWithCode() async {
    if (_busy) return;
    setState(() => _busy = true);
    _codeFocus.unfocus();

    bool success = false;
    try {
      success = await widget.model.signInWithCode(_code.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (success) return _onSignedIn();
    setState(() => _codeFailed = true);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final qrCode = capture.barcodes.firstOrNull?.rawValue;
    final coolingDown = qrCode == _failedQrCode && DateTime.now().difference(_failedAt) < _retryCooldown;
    if (!_scanning || _busy || qrCode == null || coolingDown) return;
    setState(() => _busy = true);

    // Let the morph play out first; the Keycloak sheet only opens on the
    // finished mark.
    await Future<void>.delayed(QrToCarpMorph.duration);
    if (!mounted) return;
    final success = await widget.model.signInWithQrCode(qrCode);
    if (!mounted) return;
    if (success) return _onSignedIn();
    // ponytail: a failed QR code is silently ignored for a while; a toast
    // with the reason would be the upgrade.
    setState(() {
      _busy = false;
      _failedQrCode = qrCode;
      _failedAt = DateTime.now();
    });
  }
}

/// The scan window: a rounded frame. While a scanned code is being signed in
/// it frosts over and a QR silhouette morphs into the CARP mark; if sign-in
/// fails the morph runs backwards and the window clears again.
class _ScanFrame extends StatefulWidget {
  const _ScanFrame({required this.size, required this.radius, required this.busy});
  final double size;
  final BorderRadius radius;
  final bool busy;

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: QrToCarpMorph.duration,
    reverseDuration: const Duration(milliseconds: 500),
  );

  /// The logo is sampled once; until then the frame is drawn without the morph.
  late final Future<void> _ready = QrToCarpMorph.load();

  @override
  void didUpdateWidget(_ScanFrame old) {
    super.didUpdateWidget(old);
    if (widget.busy != old.busy) widget.busy ? _morph.forward() : _morph.reverse();
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: widget.radius,
    child: SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _morph,
            builder: (context, child) => _morph.value == 0
                ? const SizedBox.shrink()
                : BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12 * _morph.value, sigmaY: 12 * _morph.value),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45 * _morph.value),
                      child: child,
                    ),
                  ),
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.14),
              child: FutureBuilder(
                future: _ready,
                builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                    ? QrToCarpMorph(progress: _morph)
                    : const SizedBox(),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Full-screen message shown instead of the camera preview.
class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}

/// A round, frosted icon button for use on top of the camera.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    ),
  );
}

/// A frosted pill switch with a sliding highlight under the selected option.
class _GlassSwitch extends StatelessWidget {
  const _GlassSwitch({required this.selected, required this.labels, required this.onSelected});

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth / labels.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: selected * width,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(shape: StadiumBorder(), color: Colors.white),
                  ),
                ),
                Row(
                  children: List.generate(labels.length, (index) {
                    final active = index == selected;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: active,
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: () => onSelected(index),
                          child: Center(
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// [LoginViewModel.codeLength] single-character text fields for a sign-in code.
/// The joined text is mirrored into [controller]; [focusNode] is the first box.
class CodeInput extends StatefulWidget {
  const CodeInput({
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCompleted;
  final VoidCallback? onChanged;
  final bool enabled;
  final bool hasError;

  /// One letter or digit per box, upper-cased.
  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
    // Typing into a filled box replaces it: keep only the last character.
    // A paste (more than one new character) is kept whole, to spread over the boxes.
    TextInputFormatter.withFunction(
      (old, v) => v.text.length <= 1 || v.text.length - old.text.length > 1
          ? v.copyWith(text: v.text.toUpperCase())
          : TextEditingValue(
              text: v.text[v.text.length - 1].toUpperCase(),
              selection: const TextSelection.collapsed(offset: 1),
            ),
    ),
  ];

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  static const int length = LoginViewModel.codeLength;
  final List<TextEditingController> _boxes = List.generate(length, (_) => TextEditingController());
  late final List<FocusNode> _focus = [widget.focusNode, ...List.generate(length - 1, (_) => FocusNode())];

  @override
  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
    for (final f in _focus.skip(1)) {
      f.dispose();
    }
    super.dispose();
  }

  void _onBoxChanged(int index, String value) {
    if (value.length > 1) return _paste(index, value);
    if (value.isNotEmpty && index < length - 1) _focus[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focus[index - 1].requestFocus();
    _publish();
  }

  /// Spread a pasted [text] over the boxes from [index] on.
  void _paste(int index, String text) {
    final chars = text.characters.take(length - index).toList();
    for (var i = 0; i < chars.length; i++) {
      _boxes[index + i].text = chars[i];
    }
    _focus[min(index + chars.length, length - 1)].requestFocus();
    _publish();
  }

  void _publish() {
    widget.controller.text = _boxes.map((c) => c.text).join();
    widget.onChanged?.call();
    if (widget.controller.text.length == length) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError ? Theme.of(context).colorScheme.error : Colors.grey.shade300;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        children: List.generate(
          length,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              // Backspace in an empty box: onChanged does not fire, so step back here.
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      _boxes[index].text.isEmpty &&
                      index > 0) {
                    _focus[index - 1].requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _boxes[index],
                  focusNode: _focus[index],
                  enabled: widget.enabled,
                  autofocus: index == 0,
                  // Focus hops between boxes must not scroll the sheet.
                  scrollPadding: EdgeInsets.zero,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: index == length - 1 ? TextInputAction.done : TextInputAction.next,
                  inputFormatters: CodeInput.formatters,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    enabledBorder: border(borderColor, widget.hasError ? 2 : 1),
                    focusedBorder: border(
                      widget.hasError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                      2,
                    ),
                  ),
                  onTap: () =>
                      _boxes[index].selection = TextSelection(baseOffset: 0, extentOffset: _boxes[index].text.length),
                  onChanged: (value) => _onBoxChanged(index, value),
                  onSubmitted: (_) => widget.onCompleted(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
