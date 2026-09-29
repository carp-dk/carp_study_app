part of carp_study_app;

/// The Connections page: the phone, then hardware devices, then services.
class ConnectionListPage extends StatefulWidget {
  static const String route = '/connections';
  final ConnectionListPageViewModel model;
  const ConnectionListPage({required this.model, super.key});

  @override
  ConnectionListPageState createState() => ConnectionListPageState();
}

class ConnectionListPageState extends State<ConnectionListPage> {
  StreamSubscription<BluetoothAdapterState>? bluetoothStateStream;
  BluetoothAdapterState? bluetoothAdapterState;
  late final AppLifecycleListener _lifecycle;

  late final List<ConnectionViewModel> _smartphoneDevice = widget.model.smartphoneDevice;
  late final List<ConnectionViewModel> _hardwareDevices = widget.model.hardwareDevices;
  late final List<ConnectionViewModel> _services = widget.model.services;

  @override
  void initState() {
    super.initState();
    bluetoothStateStream = FlutterBluePlus.adapterState.listen((state) {
      bluetoothAdapterState = state;
      setState(() {});
    });
    // Back from Settings a permission may have changed. onShow, not onResume:
    // a permission dialog only makes the app inactive, Settings hides it.
    _lifecycle = AppLifecycleListener(onShow: () => unawaited(_refreshStatuses()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
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
                locale.translate("pages.connections.message"),
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
                    if (_services.isNotEmpty) ..._servicesList(locale),
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

  /// Bring every service in line with its permissions - the cards follow via [statusEvents].
  Future<void> _refreshStatuses() async {
    for (final service in _services) {
      final manager = service.deviceManager;
      final granted = await manager.hasPermissions();
      if (granted && manager.canConnect && !manager.isConnecting) await manager.connect();
      if (!granted && manager.isConnected) await manager.disconnect();
    }
    await BackgroundSensingService().refresh();
    if (mounted) setState(() {});
  }

  /// The list of smartphones - which is a list with only one smartphone.
  List<Widget> _smartphoneDeviceList(RPLocalizations locale) => [
    ConnectionsPageListTitle(locale: locale, type: ConnectionsPageTypes.phone),
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
    ConnectionsPageListTitle(locale: locale, type: ConnectionsPageTypes.devices),
    SliverList(
      delegate: SliverChildBuilderDelegate(childCount: _hardwareDevices.length, (BuildContext context, int index) {
        ConnectionViewModel device = _hardwareDevices[index];
        return _connectionsPageCardStream(
          device.statusEvents,
          DeviceStatus.unknown,
          () => _cardListBuilder(
            enableFeedback: true,
            leading: device.icon!,
            leadingImage: device.iconImage,
            title: (locale.translate(device.typeName), device.batteryLevel ?? 0),
            subtitle: device.name,
            // Study-managed, so the user cannot disconnect it - nothing to tap.
            onTap: device.status == DeviceStatus.connected || device.status == DeviceStatus.connecting
                ? null
                : () async => await _hardwareDeviceClicked(device),
            trailing: device.getDeviceStatusIcon is Icon
                ? device.getDeviceStatusIcon as Icon
                : _connectPill(
                    locale.translate(
                      device.getDeviceStatusIcon as String? ?? "pages.connections.status.action.connect",
                    ),
                  ),
          ),
        );
      }),
    ),
  ];

  /// The services, background sensing first - the study depends on it most.
  List<Widget> _servicesList(RPLocalizations locale) => [
    ConnectionsPageListTitle(locale: locale, type: ConnectionsPageTypes.services),
    if (BackgroundSensingService().isSupported) _backgroundSensingCard(locale),
    SliverList(
      delegate: SliverChildBuilderDelegate(childCount: _services.length, (BuildContext context, int index) {
        ConnectionViewModel service = _services[index];
        return _connectionsPageCardStream(
          service.statusEvents,
          DeviceStatus.unknown,
          () => _cardListBuilder(
            leading: service.icon!,
            leadingImage: service.iconImage,
            title: (locale.translate(service.typeName), null),
            subtitle: null,
            onTap: () async => await _serviceClicked(service),
            trailing: service.getServiceStatusIcon is String
                ? _connectPill(locale.translate(service.getServiceStatusIcon as String))
                : service.getServiceStatusIcon as Icon,
          ),
        );
      }),
    ),
  ];

  /// Highlighted: without it, data is only collected while the app is open.
  Widget _backgroundSensingCard(RPLocalizations locale) => SliverToBoxAdapter(
    child: ListenableBuilder(
      listenable: BackgroundSensingService(),
      builder: (context, _) {
        final connected = BackgroundSensingService().isConnected;
        return Center(
          child: StudiesMaterial(
            backgroundColor: Colors.grey.shade50,
            hasBorder: true,
            borderColor: connected ? _statusSuccess : Theme.of(context).colorScheme.primary,
            child: _cardListBuilder(
              leading: const Icon(Icons.autorenew_rounded, size: 30, color: Color(0xff3260A4)),
              title: (locale.translate('pages.connections.type.background.name'), null),
              subtitle: locale.translate('pages.connections.type.background.description'),
              onTap: connected ? null : _backgroundSensingClicked,
              trailing: connected
                  ? const Icon(Icons.sensors_rounded, color: _statusSuccess, size: 30)
                  : _connectPill(locale.translate('pages.connections.status.action.connect')),
            ),
          ),
        );
      },
    ),
  );

  /// A label styled like a button - the whole tile is what's tappable.
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
      // Apple/Google guidelines forbid a badge behind their health logos.
      leading: leadingImage == healthPlatformIcon
          ? Image.asset(leadingImage!, width: 40, height: 40)
          // The tinted rounded-square badge shared with the task and feed cards.
          : Container(
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

  Widget _connectionsPageCardStream<T>(Stream<T> stream, T? initialData, Widget Function() childBuilder) => Center(
    child: StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
      child: StreamBuilder<T>(
        stream: stream,
        initialData: initialData,
        builder: (context, AsyncSnapshot<T> snapshot) => childBuilder(),
      ),
    ),
  );

  Future<void> _serviceClicked(ConnectionViewModel service) async {
    if (service.status == DeviceStatus.connected || service.status == DeviceStatus.connecting) {
      return;
    }

    if (!(await service.deviceManager.hasPermissions())) {
      if (!mounted) return;
      if (service.type == HealthService.DEVICE_TYPE) {
        // The page asks for access and explains a denial itself.
        Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute<void>(builder: (context) => HealthServiceConnectPage()));
      } else {
        // The location card only needs While Using - Always is background sensing's.
        service.type == LocationService.DEVICE_TYPE
            ? await Permission.locationWhenInUse.request()
            : await service.deviceManager.requestPermissions();
        if (!await service.deviceManager.hasPermissions()) {
          if (mounted) await showPermissionDeniedDialog(context, 'pages.connections.permission.message');
          return;
        }
      }
    }
    await service.deviceManager.connect();
  }

  Future<void> _backgroundSensingClicked() async {
    final background = BackgroundSensingService();
    await background.connect();
    // Only a missing permission is the user's to fix in Settings.
    if (background.isConnected || await background.isGranted || !mounted) return;
    await showPermissionDeniedDialog(
      context,
      Platform.isAndroid
          ? 'pages.connections.background_permission.message.android'
          : 'pages.connections.background_permission.message',
    );
  }

  Future<void> _hardwareDeviceClicked(ConnectionViewModel device) async {
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
        final granted = await device.deviceManager.hasPermissions();
        if (!mounted) return;
        if (!granted) {
          await showPermissionDeniedDialog(context, 'pages.connections.location_permission.message');
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
        await showPermissionDeniedDialog(context, 'pages.connections.bluetooth_permission.message');
      }
    }
  }
}

/// Explain missing permissions and offer the app settings - the OS won't ask
/// again once a permission is permanently denied, so Settings is the only way.
Future<void> showPermissionDeniedDialog(BuildContext context, String messageKey, {String? image}) {
  final locale = RPLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(locale.translate("pages.connections.location_permission.title")),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.translate(messageKey)),
            if (image != null) ...[
              const SizedBox(height: 16),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(image)),
            ],
          ],
        ),
      ),
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
    ),
  );
}
