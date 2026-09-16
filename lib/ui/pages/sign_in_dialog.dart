part of carp_study_app;

/// Anonymous sign-in: either scan the QR code of a magic link, or type in the
/// short code handed out with the study invitation.
class SignInDialog extends StatefulWidget {
  final LoginViewModel model;
  const SignInDialog({required this.model, super.key});

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> with SingleTickerProviderStateMixin {
  qr.QRViewController? controller;
  StreamSubscription<qr.Barcode>? _scanSubscription;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  late final TabController _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  bool _busy = false;
  bool _codeFailed = false;

  bool get _scanning => _tabs.index == 0;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _tabs.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  // Only the selected tab is built, so leaving the scan tab tears the camera
  // down - no pause/resume bookkeeping needed.
  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_scanning) {
      _codeFocus.unfocus();
    } else {
      _scanSubscription?.cancel();
      _scanSubscription = null;
      controller = null;
      _codeFocus.requestFocus();
    }
    setState(() {});
  }

  /// Complete the sign-in flow after a successful authentication.
  Future<void> _onSignedIn() async {
    final invitations = bloc.appViewModel.invitationsListViewModel;
    await invitations.loadInvitations();
    if (!mounted) return;
    context.go(invitations.landingRoute);
  }

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      locale.translate('pages.login.sign_in.title'),
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _SegmentedTabs(
                controller: _tabs,
                labels: [
                  locale.translate('pages.login.sign_in.tab.scan'),
                  locale.translate('pages.login.sign_in.tab.code'),
                ],
              ),
            ),
            Expanded(child: _scanning ? _buildScanTab(locale) : _buildCodeTab(locale)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTab(RPLocalizations locale) => Column(
    children: [
      Expanded(child: _buildQrView(context)),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                locale.translate('pages.login.sign_in.scan_hint'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              tooltip: locale.translate('pages.login.sign_in.flip_camera'),
              onPressed: () async {
                await controller?.flipCamera();
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildCodeTab(RPLocalizations locale) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          locale.translate('pages.login.sign_in.code_hint'),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CodeInput(
          controller: _code,
          focusNode: _codeFocus,
          enabled: !_busy,
          hasError: _codeFailed,
          onChanged: () => setState(() => _codeFailed = false),
          onCompleted: _signInWithCode,
        ),
        const SizedBox(height: 16),
        if (_codeFailed)
          Text(
            locale.translate('pages.login.sign_in.code_invalid'),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
          ),
          onPressed: _busy || _code.text.length < LoginViewModel.codeLength ? null : _signInWithCode,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(locale.translate('pages.login.login'), style: const TextStyle(color: Colors.white)),
        ),
      ],
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
    if (success) {
      await _onSignedIn();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _codeFailed = true);
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return qr.QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: qr.QrScannerOverlayShape(
        borderColor: Theme.of(context).colorScheme.primary,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    _scanSubscription = controller.scannedDataStream.listen((scanData) async {
      final qrcode = scanData.code;
      if (_busy || qrcode == null) return;
      _busy = true;
      await controller.pauseCamera();

      final success = await widget.model.signInWithMagicLink(qrcode);
      if (!mounted) return;
      if (success) await _onSignedIn();
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  void _onPermissionSet(BuildContext context, qr.QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('no Permission')));
    }
  }
}

/// A pill-shaped two-way switch between the tabs of [controller].
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(100)),
    child: TabBar(
      controller: controller,
      dividerColor: Colors.transparent,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey.shade700,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: const ShapeDecoration(shape: StadiumBorder(), color: Colors.white),
      tabs: labels.map((label) => Tab(text: label)).toList(),
    ),
  );
}

/// [LoginViewModel.codeLength] boxes showing the characters of a sign-in code.
///
/// Backed by a single text field with transparent text, so paste, backspace and
/// screen readers work as usual. Anything but letters and digits is filtered
/// away, also when pasted, and letters are upper-cased.
class CodeInput extends StatelessWidget {
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

  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
    LengthLimitingTextInputFormatter(LoginViewModel.codeLength),
    TextInputFormatter.withFunction((_, value) => value.copyWith(text: value.text.toUpperCase())),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: AnimatedBuilder(
            animation: Listenable.merge([controller, focusNode]),
            builder: (context, _) =>
                Row(children: List.generate(LoginViewModel.codeLength, (index) => _buildBox(context, index))),
          ),
        ),
        // The real input, laid out over the boxes with invisible text.
        Positioned.fill(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            autofocus: true,
            showCursor: false,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: formatters,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: (value) {
              onChanged?.call();
              if (value.length == LoginViewModel.codeLength) onCompleted();
            },
            onSubmitted: (_) => onCompleted(),
          ),
        ),
      ],
    ),
  );

  Widget _buildBox(BuildContext context, int index) {
    final text = controller.text;
    final filled = index < text.length;
    final active = focusNode.hasFocus && index == text.length.clamp(0, LoginViewModel.codeLength - 1);
    final color = hasError
        ? Theme.of(context).colorScheme.error
        : active
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: active || hasError ? 2 : 1),
        ),
        child: Text(
          filled ? text[index] : '',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade900),
        ),
      ),
    );
  }
}
