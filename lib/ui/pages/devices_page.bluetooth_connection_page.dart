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
        backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
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
                                child: SizedBox(child: _buildStepContent(locale)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                mainAxisAlignment: currentStep == CurrentStep.done
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.spaceBetween,
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
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTitle(RPLocalizations locale) {
    final stepTitleMap = {
      CurrentStep.scan: locale.translate("pages.devices.connection.step.start.title"),
      CurrentStep.instructions: locale.translate("pages.devices.connection.step.how_to.title"),
      CurrentStep.done:
          locale.translate("pages.devices.connection.step.confirm.title") + (" ${selectedDevice?.platformName} "),
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
                style: fs22fw700.copyWith(color: Theme.of(context).primaryColor),
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
    Widget buildTranslatedButton(
      String key,
      VoidCallback onPressed,
      bool enabled,
      ButtonStyle? buttonStyle,
      TextStyle? buttonTextStyle,
    ) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(locale.translate(key).toUpperCase(), style: buttonTextStyle),
        style: buttonStyle,
      );
    }

    final stepButtonConfigs = {
      CurrentStep.scan: [
        buildTranslatedButton(
          "cancel",
          () {
            context.pop(true);
          },
          true,
          null,
          null,
        ),
        buildTranslatedButton(
          "next",
          _connectDevice(),
          selectedDevice != null,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<CarpColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(color: Colors.white),
        ),
      ],
      CurrentStep.instructions: [
        buildTranslatedButton(
          "settings",
          () {
            Platform.isAndroid ? OpenSettingsPlusAndroid().bluetooth() : OpenSettingsPlusIOS().bluetooth();
          },
          true,
          null,
          null,
        ),
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
          TextStyle(color: Colors.white),
        ),
      ],
      // The device is connected at this point, so there is nothing to go back
      // to - only 'done' is offered.
      CurrentStep.done: [
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
          TextStyle(color: Colors.white),
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(locale.translate("ok")),
              ),
            ],
          );
        },
      );
      // Tear the connection attempt down instead of only stamping the status:
      // the native SDK otherwise keeps the link open and retries in the
      // background, leaving the device connected in reality but shown as
      // disconnected in the app.
      widget.device.deviceManager.disconnect();
    }
  });

  Widget stepContent(CurrentStep currentStep, DeviceViewModel device) {
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
          if (device.bleNamePrefix != null)
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
                  style: fs16fw400.copyWith(fontSize: 14),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snapshot) {
                // Show devices whose advertised name contains this type's prefix
                // (e.g. "Polar", "Movesense"), so the user can't pick the wrong
                // device type. "Show all" is the escape hatch for anything the
                // filter would otherwise hide.
                final prefix = device.bleNamePrefix?.toLowerCase();
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
                      style: fs16fw400.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey700),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: results
                          .map(
                            (r) => StudiesMaterial(
                              // hasBorder: true,
                              backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
                              child: InkWell(
                                child: ListTile(
                                  selected: r.device.remoteId == selectedDevice?.remoteId,
                                  title: Text(r.device.platformName, style: fs22fw700.copyWith(fontSize: 20)),
                                  selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedDevice = r.device;
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: locale.translate("pages.devices.connection.step.start.1")),
                  TextSpan(
                    text: locale.translate("pages.devices.connection.instructions"),
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
                  TextSpan(text: locale.translate("pages.devices.connection.step.start.2")),
                ],
              ),
              style: fs22fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
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
