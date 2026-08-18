part of carp_study_app;

/// State of Bluetooth connection UI.
enum CurrentStep { scan, instructions, done }

class BluetoothConnectionPage extends StatefulWidget {
  final DeviceViewModel device;

  const BluetoothConnectionPage(CurrentStep currentStep, {super.key, required this.device})
    : _currentStep = currentStep;

  final CurrentStep _currentStep;

  @override
  State<StatefulWidget> createState() => _BluetoothConnectionPageState(_currentStep);
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  _BluetoothConnectionPageState(this.currentStep);

  CurrentStep currentStep;
  bool isConnecting = false;
  Timer? _connectionTimeoutTimer;
  StreamSubscription<DeviceStatus>? _statusSubscription;

  @override
  initState() {
    super.initState();
    FlutterBluePlus.startScan();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    _connectionTimeoutTimer?.cancel();
    _statusSubscription?.cancel();
    LocalSettings().hasSeenBluetoothConnectionInstructions = true;
    super.dispose();
  }

  BluetoothDevice? selectedDevice;
  bool showAllDevices = false;

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return PopScope(
      // The device is connected on the last step - leave only via 'done', so
      // the system back gesture does not skip past the confirmation.
      canPop: currentStep != CurrentStep.done,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade700,
                        onPressed: () => context.pop(true),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogTitle(locale),
                          Expanded(child: _buildStepContent()),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      mainAxisAlignment: currentStep == CurrentStep.done
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.spaceBetween,
                      children: _buildActionButtons(locale),
                    ),
                  ),
                ],
              ),
              if (isConnecting)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTitle(RPLocalizations locale) {
    final deviceTypeName = locale.translate(widget.device.typeName);
    final stepTitleMap = {
      CurrentStep.scan: "${locale.translate("pages.devices.connection.step.start.title")} $deviceTypeName",
      CurrentStep.instructions: locale.translate("pages.devices.connection.step.how_to.title"),
      CurrentStep.done:
          "${locale.translate("pages.devices.connection.step.confirm.title")} ${selectedDevice?.platformName ?? ''}",
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        stepTitleMap[currentStep] ?? '',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.grey.shade900),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case CurrentStep.scan:
        return scanWidget(context);
      case CurrentStep.instructions:
        return connectionInstructions(widget.device, context);
      case CurrentStep.done:
        return confirmDevice(selectedDevice, context);
    }
  }

  List<Widget> _buildActionButtons(RPLocalizations locale) {
    final hasSelection = selectedDevice != null;

    final stepButtonConfigs = {
      CurrentStep.scan: [
        TextButton(onPressed: () => context.pop(true), child: Text(locale.translate("cancel"))),
        FilledButton(onPressed: hasSelection ? _connectDevice() : null, child: Text(locale.translate("next"))),
      ],
      CurrentStep.instructions: [
        TextButton(
          onPressed: () =>
              Platform.isAndroid ? OpenSettingsPlusAndroid().bluetooth() : OpenSettingsPlusIOS().bluetooth(),
          child: Text(locale.translate("settings")),
        ),
        FilledButton(
          onPressed: () => setState(() => currentStep = CurrentStep.scan),
          child: Text(locale.translate("ok")),
        ),
      ],
      // The device is connected at this point, so there is nothing to go back
      // to - only 'done' is offered.
      CurrentStep.done: [
        const Spacer(),
        FilledButton(
          onPressed: () {
            FlutterBluePlus.stopScan();
            context.pop(true);
          },
          child: Text(locale.translate("done")),
        ),
      ],
    };
    return stepButtonConfigs[currentStep] ?? [];
  }

  Future<void> Function() _connectDevice() {
    return () async {
      RPLocalizations locale = RPLocalizations.of(context)!;
      if (selectedDevice != null) {
        setState(() {
          isConnecting = true;
        });

        FlutterBluePlus.stopScan();
        widget.device.connectToDevice(selectedDevice!);
        // Repeated connect attempts must not stack listeners.
        _statusSubscription?.cancel();
        _statusSubscription = widget.device.statusEvents.listen((state) {
          if (state == DeviceStatus.connected) {
            _connectionTimeoutTimer?.cancel();
            if (mounted) {
              setState(() {
                currentStep = CurrentStep.done;
                isConnecting = false;
              });
            }
          } else if (state == DeviceStatus.reconnected) {
            // BLE link is up; some devices (e.g. Polar) only reach `connected`
            // after negotiating SDK features and data types. Give that extra time.
            _connectionTimeoutTimer?.cancel();
            _connectionTimeoutTimer = _startConnectionTimeout(locale);
          } else if (state == DeviceStatus.disconnected) {
            _connectionTimeoutTimer?.cancel();
            if (mounted) {
              setState(() {
                currentStep = CurrentStep.scan;
                isConnecting = false;
              });
              FlutterBluePlus.startScan();
            }
          }
        });

        _connectionTimeoutTimer = _startConnectionTimeout(locale);
      }
    };
  }

  /// Fail the connection attempt if the device does not reach
  /// [DeviceStatus.connected] within the timeout.
  Timer _startConnectionTimeout(RPLocalizations locale) => Timer(const Duration(seconds: 7), () {
    if (isConnecting && mounted) {
      setState(() {
        isConnecting = false;
      });
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(locale.translate("pages.devices.connection.connection_failed.title")),
            content: Text(locale.translate("pages.devices.connection.connection_failed.message")),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(locale.translate("ok")),
              ),
            ],
          );
        },
      );
      // Tear down the attempt, else the native SDK keeps the link open and
      // retries in the background while the app shows it as disconnected.
      widget.device.deviceManager.disconnect();
    }
  });

  Widget scanWidget(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    final prefix = widget.device.bleNamePrefix?.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prefix != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => showAllDevices = !showAllDevices),
              child: Text(
                locale.translate(
                  showAllDevices
                      ? "pages.devices.connection.step.scan.filtered"
                      : "pages.devices.connection.step.scan.show_all",
                ),
                style: Theme.of(context).textTheme.labelLarge!,
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            initialData: const [],
            builder: (context, snapshot) {
              // Only show devices whose name contains this type's prefix, so
              // the wrong device can't be picked. "Show all" is the escape hatch.
              final results = snapshot.data!.where((r) {
                // Skip nameless devices - they can't be identified or paired.
                final name = r.device.platformName;
                if (name.isEmpty) return false;
                if (showAllDevices || prefix == null) return true;
                return name.toLowerCase().contains(prefix);
              }).toList();

              if (results.isEmpty) {
                return Center(
                  child: Text(
                    locale.translate("pages.devices.connection.step.scan.searching"),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final r in results)
                    _deviceTile(
                      icon: Icons.monitor_heart,
                      name: r.device.platformName,
                      selected: selectedDevice?.remoteId == r.device.remoteId,
                      onTap: () => setState(() => selectedDevice = r.device),
                    ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: locale.translate("pages.devices.connection.step.start.1")),
                TextSpan(
                  text: locale.translate("pages.devices.connection.instructions"),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => setState(() => currentStep = CurrentStep.instructions),
                ),
                TextSpan(text: locale.translate("pages.devices.connection.step.start.2")),
              ],
            ),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  /// A selectable device card: icon + name, with a primary-coloured border and
  /// tint when [selected].
  Widget _deviceTile({
    required IconData icon,
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: selected ? primary.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? primary : Colors.grey.shade300, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget connectionInstructions(DeviceViewModel device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    AssetImage? assetImage;

    switch (device.deviceManager) {
      case PolarDeviceManager _
          when device.type == PolarDevice.DEVICE_TYPE &&
              (device.polarDeviceType == PolarDeviceType.H10 || device.polarDeviceType == PolarDeviceType.H9):
        assetImage = AssetImage('assets/instructions/polar_h9_h10_instructions.png');
        break;

      case PolarDeviceManager _
          when device.type == PolarDevice.DEVICE_TYPE && device.polarDeviceType == PolarDeviceType.Verity:
        assetImage = AssetImage('assets/instructions/polar_sense_instructions.png');
        break;

      // if device type is not defined in the protocol, show h9, h10 instructions
      case PolarDeviceManager _:
        assetImage = AssetImage('assets/instructions/polar_h9_h10_instructions.png');
        break;

      case MovesenseDeviceManager _:
        assetImage = AssetImage('assets/instructions/movesense_instructions.png');
        break;

      default:
        assetImage = AssetImage('assets/instructions/connect_to_hw.png');
    }

    Image connectionImage = Image(
      image: assetImage,
      width: MediaQuery.of(context).size.height * 0.3,
      height: MediaQuery.of(context).size.height * 0.3,
    );
    // Split the instruction paragraph into one bullet per sentence.
    final steps = locale
        .translate(device.connectionInstructions!)
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: connectionImage),
                  const SizedBox(height: 8),
                  for (final step in steps) _bullet(step),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A single bulleted instruction line.
  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 10),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: Colors.grey.shade700, shape: BoxShape.circle),
          ),
        ),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.3))),
      ],
    ),
  );

  Widget confirmDevice(BluetoothDevice? device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    final deviceName = device?.platformName ?? '';
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _connectedDevicesMock(locale),
        const SizedBox(height: 32),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "${locale.translate("pages.devices.connection.step.confirm.1")} "),
              TextSpan(
                text: deviceName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: " ${locale.translate("pages.devices.connection.step.confirm.2")}"),
            ],
          ),
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.4),
        ),
      ],
    );
  }

  /// A small phone-frame preview showing the connected device in the app's
  /// Devices list, mirroring where it will appear after connecting.
  Widget _connectedDevicesMock(RPLocalizations locale) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_other, color: Colors.grey.shade900, size: 22),
                const SizedBox(width: 8),
                Text(
                  locale.translate("app_home.nav_bar_item.connections"),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.grey.shade900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffEB4B62).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.monitor_heart, color: Color(0xffEB4B62), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locale.translate(widget.device.typeName),
                      style: Theme.of(context).textTheme.labelLarge!,
                    ),
                  ),
                  Icon(Icons.bluetooth_rounded, color: primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
