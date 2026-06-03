part of carp_study_app;

/// State of Bluetooth connection UI.
enum CurrentStep { scan, instructions, done }

class BluetoothConnectionPage extends StatefulWidget {
  final DeviceViewModel device;

  const BluetoothConnectionPage(CurrentStep currentStep,
      {super.key, required this.device})
      : _currentStep = currentStep;

  final CurrentStep _currentStep;

  @override
  State<StatefulWidget> createState() =>
      _BluetoothConnectionPageState(_currentStep);
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  _BluetoothConnectionPageState(this.currentStep);

  CurrentStep currentStep;
  bool isConnecting = false;
  Timer? _connectionTimeoutTimer;

  @override
  initState() {
    super.initState();
    FlutterBluePlus.startScan();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    _connectionTimeoutTimer?.cancel();
    LocalSettings().hasSeenBluetoothConnectionInstructions = true;
    super.dispose();
  }

  BluetoothDevice? selectedDevice;
  int selected = 40;

  /// Set of normalized UUIDs (no dashes, lower-case) to filter discovered devices by
  /// If empty, no UUID filtering is applied.
  final Set<String> _filterUuids = <String>{};

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16),
                    child: const CarpAppBar(hasProfileIcon: true),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          _buildDialogTitle(locale),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                child: _buildStepContent(locale),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _buildActionButtons(locale),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTitle(RPLocalizations locale) {
    final stepTitleMap = {
      CurrentStep.scan:
          locale.translate("pages.devices.connection.step.start.title"),
      CurrentStep.instructions:
          locale.translate("pages.devices.connection.step.how_to.title"),
      CurrentStep.done:
          locale.translate("pages.devices.connection.step.confirm.title") +
              (" ${selectedDevice?.platformName} "),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                stepTitleMap[currentStep] ?? '',
                style: fs22fw700.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(RPLocalizations locale) {
    final stepContentMap = {
      CurrentStep.scan: stepContent(currentStep, widget.device),
      CurrentStep.instructions: connectionInstructions(widget.device, context),
      CurrentStep.done: confirmDevice(selectedDevice, context),
    };

    return stepContentMap[currentStep] ?? Container();
  }

  List<Widget> _buildActionButtons(RPLocalizations locale) {
    Widget buildTranslatedButton(String key, VoidCallback onPressed,
        bool enabled, ButtonStyle? buttonStyle, TextStyle? buttonTextStyle) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(
          locale.translate(key).toUpperCase(),
          style: buttonTextStyle,
        ),
        style: buttonStyle,
      );
    }

    final stepButtonConfigs = {
      CurrentStep.scan: [
        buildTranslatedButton("cancel", () {
          context.pop(true);
        }, true, null, null),
        buildTranslatedButton(
          "next",
          _connectDevice(),
          selectedDevice != null,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<CarpColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(
            color: Colors.white,
          ),
        ),
      ],
      CurrentStep.instructions: [
        buildTranslatedButton("settings", () {
          Platform.isAndroid
              ? OpenSettingsPlusAndroid().bluetooth()
              : OpenSettingsPlusIOS().bluetooth();
        }, true, null, null),
        buildTranslatedButton(
          "ok",
          () {
            setState(() => currentStep = CurrentStep.scan);
          },
          true,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<CarpColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(
            color: Colors.white,
          ),
        ),
      ],
      CurrentStep.done: [
        buildTranslatedButton("back", () {
          setState(() => currentStep = CurrentStep.scan);
        }, true, null, null),
        buildTranslatedButton(
          "done",
          () {
            FlutterBluePlus.stopScan();
            context.pop(true);
          },
          true,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<CarpColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(
            color: Colors.white,
          ),
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
        widget.device.statusEvents.listen((state) {
          if (state == DeviceStatus.connected) {
            _connectionTimeoutTimer?.cancel();
            if (mounted) {
              setState(() {
                currentStep = CurrentStep.done;
                isConnecting = false;
              });
            }
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

        // Start 7-second timeout
        _connectionTimeoutTimer = Timer(const Duration(seconds: 7), () {
          if (isConnecting && mounted) {
            setState(() {
              isConnecting = false;
            });
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(locale.translate(
                      "pages.devices.connection.connection_failed.title")),
                  content: Text(locale.translate(
                      "pages.devices.connection.connection_failed.message")),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(locale.translate("ok")),
                    ),
                  ],
                );
              },
            );
            widget.device.status = DeviceStatus.disconnected;
          }
        });
      }
    };
  }

  Widget stepContent(
    CurrentStep currentStep,
    DeviceViewModel device,
  ) {
    if (currentStep == CurrentStep.scan) {
      return scanWidget(device, context);
    } else if (currentStep == CurrentStep.instructions) {
      return connectionInstructions(device, context);
    } else {
      return confirmDevice(selectedDevice, context);
    }
  }

  Widget scanWidget(DeviceViewModel device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            "${locale.translate("pages.devices.connection.step.scan.1")} "
            "${locale.translate(device.typeName)} "
            "${locale.translate("pages.devices.connection.step.scan.2")}",
            style: fs22fw700,
            textAlign: TextAlign.justify,
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snapshot) => Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: snapshot.data!
                        .where((element) =>
                            element.device.platformName.isNotEmpty &&
                            _matchesUuid(element, _filterUuids))
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (bluetoothDevice) => StudiesMaterial(
                            // hasBorder: true,
                            backgroundColor: Theme.of(context)
                                .extension<CarpColors>()!
                                .grey50!,
                            child: InkWell(
                              child: ListTile(
                                selected: bluetoothDevice.key == selected,
                                title: Text(
                                  bluetoothDevice.value.device.platformName,
                                  style: fs22fw700.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                selectedTileColor: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                              ),
                              onTap: () {
                                selectedDevice = bluetoothDevice.value.device;
                                setState(() {
                                  selected = bluetoothDevice.key;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: locale
                        .translate("pages.devices.connection.step.start.1"),
                  ),
                  TextSpan(
                    text: locale
                        .translate("pages.devices.connection.instructions"),
                    style: TextStyle(
                      color: Theme.of(context).extension<CarpColors>()!.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        setState(() => currentStep = CurrentStep.instructions);
                      },
                  ),
                  TextSpan(
                    text: locale.translate(
                      "pages.devices.connection.step.start.2",
                    ),
                  ),
                ],
              ),
              style: fs22fw700.copyWith(
                  color: Theme.of(context).extension<CarpColors>()!.grey900),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  /// Returns true if [scanResult] advertises any UUID present in [filterUuids].
  /// If [filterUuids] is empty, always returns true.
  bool _matchesUuid(ScanResult scanResult, Set<String> filterUuids) {
    if (filterUuids.isEmpty) return true;

    // Normalize helper: remove dashes and lowercase
    String normalize(String u) => u.replaceAll('-', '').toLowerCase();

    try {
      // FlutterBluePlus ScanResult contains advertisementData with serviceUuids
      final adv = scanResult.advertisementData;
      final serviceUuids = adv.serviceUuids;
      for (var u in serviceUuids) {
        final us = u.toString();
        if (filterUuids.contains(normalize(us))) return true;
      }

      // Also check device id (remoteId) as fallback
      final devId = scanResult.device.remoteId.str;
      if (filterUuids.contains(normalize(devId))) return true;
    } catch (_) {
      // If structure differs, fall back to allowing the device
      return true;
    }

    return false;
  }

  Widget connectionInstructions(DeviceViewModel device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    AssetImage? assetImage;

    switch (device.deviceManager) {
      case PolarDeviceManager _
          when device.type == PolarDevice.DEVICE_TYPE &&
              (device.polarDeviceType == PolarDeviceType.H10 ||
                  device.polarDeviceType == PolarDeviceType.H9):
        assetImage =
            AssetImage('assets/instructions/polar_h9_h10_instructions.png');
        break;

      case PolarDeviceManager _
          when device.type == PolarDevice.DEVICE_TYPE &&
              device.polarDeviceType == PolarDeviceType.SENSE:
        assetImage =
            AssetImage('assets/instructions/polar_sense_instructions.png');
        break;

      // if device type is not defined in the protocol, show h9, h10 instructions
      case PolarDeviceManager _:
        assetImage =
            AssetImage('assets/instructions/polar_h9_h10_instructions.png');
        break;

      case MovesenseDeviceManager _:
        assetImage =
            AssetImage('assets/instructions/movesense_instructions.png');
        break;

      default:
        assetImage = AssetImage('assets/instructions/connect_to_hw.png');
    }

    Image connectionImage = Image(
      image: assetImage,
      width: MediaQuery.of(context).size.height * 0.3,
      height: MediaQuery.of(context).size.height * 0.3,
    );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  connectionImage,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      locale.translate(device.connectionInstructions!),
                      style: fs16fw400,
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget confirmDevice(BluetoothDevice? device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image(
                    image: const AssetImage('assets/icons/connection_done.png'),
                    width: MediaQuery.of(context).size.height * 0.2,
                    height: MediaQuery.of(context).size.height * 0.2),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    ("${locale.translate("pages.devices.connection.step.confirm.1")} '${device?.platformName}' ${locale.translate("pages.devices.connection.step.confirm.2")}")
                        .trim(),
                    style: fs16fw400,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
