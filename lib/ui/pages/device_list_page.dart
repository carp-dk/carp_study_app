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
    final locale = RPLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: const CarpAppBar(hasProfileIcon: true),
            ),
            CarpPageTitle(locale.translate('app_home.nav_bar_item.connections')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                locale.translate("pages.devices.message"),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.grey.shade600, height: 1.4),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshStatuses,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    ..._smartphoneDeviceList(locale),
                    if (_hardwareDevices.isNotEmpty) ..._hardwareDevicesList(locale),
                    if (_onlineServices.isNotEmpty) ..._onlineServicesList(locale),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
              backgroundColor: Colors.grey.shade50,
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
            leadingImage: device.type == MovesenseDevice.DEVICE_TYPE ? 'assets/icons/movesense_logo.png' : null,
            title: (locale.translate(device.typeName), device.batteryLevel ?? 0),
            subtitle: device.name,
            // A connected device is managed by the study and cannot be
            // disconnected by the user, so there is nothing to tap.
            onTap: device.status == DeviceStatus.connected || device.status == DeviceStatus.connecting
                ? null
                : () async => await _hardwareDeviceClicked(device),
            trailing: device.getDeviceStatusIcon is Icon
                ? device.getDeviceStatusIcon as Icon
                : _connectPill(
                    locale.translate(device.getDeviceStatusIcon as String? ?? "pages.devices.status.action.connect"),
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
                ? _connectPill(locale.translate(service.getServiceStatusIcon as String))
                : service.getServiceStatusIcon as Icon,
          ),
        );
      }),
    ),
  ];

  /// The visual "Connect" pill shown as a card's trailing widget. The whole
  /// tile is tappable, so this is a label styled like the themed FilledButton,
  /// not an interactive button.
  Widget _connectPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(100)),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onPrimary),
    ),
  );

  Widget _cardListBuilder({
    bool enableFeedback = false,
    Icon? leading,
    String? leadingImage,
    (String, int?)? title,
    String? subtitle,
    void Function()? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      minVerticalPadding: 0,
      enableFeedback: enableFeedback,
      // The tinted rounded-square badge shared with the task and feed cards.
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (leading?.color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: leadingImage != null
            ? Image.asset(leadingImage, width: 24, height: 24)
            : Icon(leading!.icon, color: leading.color ?? Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title!.$1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge!,
            ),
          ),
          if (title.$2 != null && title.$2! > 0) ...[
            const SizedBox(width: 6),
            BatteryPercentage(batteryLevel: title.$2!),
          ],
        ],
      ),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _devicesPageCardStream<T>(Stream<T> stream, T? initialData, Widget Function() childBuilder) => Center(
    child: StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
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
        Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute<void>(builder: (context) => HealthServiceConnectPage()));
      } else if (service.type == LocationService.DEVICE_TYPE) {
        final status = await Permission.locationWhenInUse.request();
        // Permanently denied/restricted: the OS won't prompt again, so send the
        // user to Settings instead of silently doing nothing.
        if (status.isPermanentlyDenied || status.isRestricted) {
          await openAppSettings();
          return;
        }
        if (!status.isGranted) return;
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
        // Request the BLE permissions the device manager declares before scanning.
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
        Navigator.of(context, rootNavigator: true).push(
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
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
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
