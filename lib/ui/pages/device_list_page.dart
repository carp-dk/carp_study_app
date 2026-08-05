part of carp_study_app;

/// The page showing the list of devices and online services, ordered as:
///  * The Smartphone device (primary device)
///  * Any hardware devices (connected devices)
///  * Any online services (connected services)
class DeviceListPage extends StatefulWidget {
  static const String route = '/devices';
  final DeviceListPageViewModel model;
  const DeviceListPage({required this.model, super.key});

  @override
  DeviceListPageState createState() => DeviceListPageState();
}

class DeviceListPageState extends State<DeviceListPage> {
  StreamSubscription<BluetoothAdapterState>? bluetoothStateStream;
  BluetoothAdapterState? bluetoothAdapterState;

  late final List<DeviceViewModel> _smartphoneDevice = widget.model.smartphoneDevice;
  late final List<DeviceViewModel> _hardwareDevices = widget.model.hardwareDevices;
  late final List<DeviceViewModel> _onlineServices = widget.model.onlineServices;

  @override
  void initState() {
    super.initState();
    bluetoothStateStream = FlutterBluePlus.adapterState.listen((state) {
      bluetoothAdapterState = state;
      setState(() {});
    });
  }

  @override
  void dispose() {
    bluetoothStateStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: const CarpAppBar(hasProfileIcon: true),
            ),
            Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.translate('pages.devices.title'),
                        style: fs24fw700.copyWith(
                          color: Theme.of(context).extension<CarpColors>()!.grey900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.translate("pages.devices.message"),
                        style: fs16fw600.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: RefreshIndicator(
                onRefresh: _refreshStatuses,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    ..._smartphoneDeviceList(locale),
                    if (_hardwareDevices.isNotEmpty) ..._hardwareDevicesList(locale),
                    if (_onlineServices.isNotEmpty) ..._onlineServicesList(locale),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Re-check the current permission/connection state of all services (e.g.
  /// after the user grants access in system settings). Status changes flow to
  /// the cards via their [statusEvents] streams.
  Future<void> _refreshStatuses() async {
    for (final service in _onlineServices) {
      await service.deviceManager.hasPermissions();
    }
    if (mounted) setState(() {});
  }

  /// The list of smartphones - which is a list with only one smartphone.
  List<Widget> _smartphoneDeviceList(RPLocalizations locale) => [
    DevicesPageListTitle(locale: locale, type: DevicesPageTypes.phone),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: _smartphoneDevice.length,
        (BuildContext context, int index) => ListenableBuilder(
          listenable: _smartphoneDevice[index],
          builder: (BuildContext context, Widget? widget) => Center(
            child: StudiesMaterial(
              backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
              child: _cardListBuilder(
                leading: _smartphoneDevice[index].icon!,
                title: (
                  "${_smartphoneDevice[index].phoneInfo["model"]!} "
                      "- ${_smartphoneDevice[index].phoneInfo["version"]!}",
                  _smartphoneDevice[index].batteryLevel ?? 0,
                ),
                subtitle: _smartphoneDevice[index].phoneInfo['name']!,
              ),
            ),
          ),
        ),
      ),
    ),
  ];

  /// The list of connected hardware devices (like a Polar sensor)
  List<Widget> _hardwareDevicesList(RPLocalizations locale) => [
    DevicesPageListTitle(locale: locale, type: DevicesPageTypes.devices),
    SliverList(
      delegate: SliverChildBuilderDelegate(childCount: _hardwareDevices.length, (BuildContext context, int index) {
        DeviceViewModel device = _hardwareDevices[index];
        return _devicesPageCardStream(
          device.statusEvents,
          DeviceStatus.unknown,
          () => _cardListBuilder(
            enableFeedback: true,
            leading: device.icon!,
            title: (locale.translate(device.typeName), device.batteryLevel ?? 0),
            subtitle: device.name,
            // A connected device is managed by the study and cannot be
            // disconnected by the user, so there is nothing to tap.
            onTap: device.status == DeviceStatus.connected || device.status == DeviceStatus.connecting
                ? null
                : () async => await _hardwareDeviceClicked(device),
            trailing: device.getDeviceStatusIcon is Icon
                ? device.getDeviceStatusIcon as Icon
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: CACHET.DEPLOYMENT_DEPLOYING,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      locale.translate(device.getDeviceStatusIcon as String? ?? "pages.devices.status.action.connect"),
                      style: fs20fw700.copyWith(color: Colors.white),
                    ),
                  ),
          ),
        );
      }),
    ),
  ];

  /// The list of online services (like a Location service)
  List<Widget> _onlineServicesList(RPLocalizations locale) => [
    DevicesPageListTitle(locale: locale, type: DevicesPageTypes.services),
    SliverList(
      delegate: SliverChildBuilderDelegate(childCount: _onlineServices.length, (BuildContext context, int index) {
        DeviceViewModel service = _onlineServices[index];
        return _devicesPageCardStream(
          service.statusEvents,
          DeviceStatus.unknown,
          () => _cardListBuilder(
            leading: service.icon!,
            title: (locale.translate(service.typeName), null),
            subtitle: null,
            onTap: () async => await _onlineServiceClicked(service),
            trailing: service.getServiceStatusIcon is String
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: CACHET.DEPLOYMENT_DEPLOYING,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      locale.translate(service.getServiceStatusIcon as String),
                      style: fs20fw700.copyWith(color: Colors.white),
                    ),
                  )
                : service.getServiceStatusIcon as Icon,
          ),
        );
      }),
    ),
  ];

  Widget _cardListBuilder({
    bool enableFeedback = false,
    Icon? leading,
    (String, int?)? title,
    String? subtitle,
    void Function()? onTap,
    Widget? trailing,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    enableFeedback: enableFeedback,
    leading: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [leading!],
    ),
    title: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title!.$1, style: fs16fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900)),
          SizedBox(width: 6),
          if (title.$2 != null && title.$2! > 0) BatteryPercentage(batteryLevel: title.$2 ?? 0),
        ],
      ),
    ),
    subtitle: subtitle != null && subtitle.isNotEmpty
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: fs12fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey700),
                ),
              ),
            ],
          )
        : null,
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [?trailing],
    ),
    onTap: onTap,
  );

  Widget _devicesPageCardStream<T>(Stream<T> stream, T? initialData, Widget Function() childBuilder) => Center(
    child: StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
      child: StreamBuilder<T>(
        stream: stream,
        initialData: initialData,
        builder: (context, AsyncSnapshot<T> snapshot) => childBuilder(),
      ),
    ),
  );

  Future<void> _onlineServiceClicked(DeviceViewModel service) async {
    if (service.status == DeviceStatus.connected || service.status == DeviceStatus.connecting) {
      return;
    }

    if (!(await service.deviceManager.hasPermissions())) {
      if (service.type == HealthService.DEVICE_TYPE) {
        Navigator.push(context, MaterialPageRoute<void>(builder: (context) => HealthServiceConnectPage()));
      } else {
        await service.deviceManager.requestPermissions();
      }
    }
    await service.deviceManager.connect();
  }

  Future<void> _hardwareDeviceClicked(DeviceViewModel device) async {
    // fast out if no Bluetooth
    if (!(await FlutterBluePlus.isSupported)) return;

    // turn on bluetooth if we can
    if (Platform.isAndroid) await FlutterBluePlus.turnOn();

    if (context.mounted) {
      if (bluetoothAdapterState == BluetoothAdapterState.off && Platform.isIOS) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => EnableBluetoothDialog(device: device),
        );
      } else if (bluetoothAdapterState == BluetoothAdapterState.on) {
        // The device manager declares the permissions BLE needs (bluetooth +
        // location on Android); request them before opening the scan page.
        if (!await device.deviceManager.hasPermissions()) {
          await device.deviceManager.requestPermissions();
        }
        if (!mounted) return;
        if (!await device.deviceManager.hasPermissions()) {
          await showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (context) => _permissionDeniedDialog(context),
          );
          return;
        }

        final hasSeenInstructions = LocalSettings().hasSeenBluetoothConnectionInstructions;
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => BluetoothConnectionPage(
              hasSeenInstructions ? CurrentStep.scan : CurrentStep.instructions,
              device: device,
            ),
          ),
        );
      } else if (bluetoothAdapterState == BluetoothAdapterState.unauthorized && Platform.isIOS) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => AuthorizationDialog(device: device),
        );
      }
    }
  }

  /// Dialog shown when the BLE permissions are still denied after requesting,
  /// pointing the user to the app settings.
  Widget _permissionDeniedDialog(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    return AlertDialog(
      title: Text(locale.translate("pages.devices.location_permission.title")),
      content: SingleChildScrollView(child: Text(locale.translate("pages.devices.location_permission.message"))),
      actions: [
        TextButton(child: Text(locale.translate("cancel")), onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).extension<CarpColors>()!.primary),
          child: Text(locale.translate("settings"), style: const TextStyle(color: Colors.white)),
          onPressed: () {
            Platform.isAndroid ? OpenSettingsPlusAndroid().applicationDetails() : OpenSettingsPlusIOS().appSettings();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
