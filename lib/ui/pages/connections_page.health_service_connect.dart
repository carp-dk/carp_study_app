part of carp_study_app;

/// Connects to Apple Health / Health Connect - from the Connections page, or
/// for a protocol health [userTask], which then collects its health data.
class HealthServiceConnectPage extends StatelessWidget {
  final UserTask? userTask;
  const HealthServiceConnectPage({super.key, this.userTask});

  HealthServiceManager get _manager =>
      DeviceController().getDeviceManager(HealthService.DEVICE_TYPE) as HealthServiceManager;

  /// The health data types the protocol asks for - of this task, or of the whole study.
  /// The task's probes are initialized by [UserTask.onStart], which also adds their types to [_manager].
  List<HealthDataType> get _types => userTask == null
      ? _manager.types
      : userTask!.backgroundTaskExecutor.probes
            .whereType<HealthProbe>()
            .expand((probe) => probe.samplingConfiguration.healthDataTypes)
            .toSet()
            .toList();

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return PopScope(
      // Leaving without connecting puts the task back on the list.
      onPopInvokedWithResult: (_, _) {
        if (userTask?.state == UserTaskState.started) userTask!.onCancel();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Container(
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18), child: const CarpAppBar()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              Platform.isAndroid
                                  ? 'assets/instructions/google_health_connect_preview.png'
                                  : 'assets/instructions/apple_health_preview.png',
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name next to the logo, as Apple's HealthKit guidelines require.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(healthPlatformIcon, width: 40, height: 40),
                            const SizedBox(width: 12),
                            Flexible(child: Text(healthPlatformName, style: Theme.of(context).textTheme.titleLarge!)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _dataDisclosure(context, locale),
                        const SizedBox(height: 20),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "${locale.translate("pages.connections.type.health.instructions.page2.part1")} ",
                                style: Theme.of(context).textTheme.titleLarge!,
                              ),
                              TextSpan(
                                text:
                                    "${Platform.isAndroid ? locale.translate("pages.connections.type.health.instructions.page2.android.allow_all") : locale.translate("pages.connections.type.health.instructions.page2.ios.turn_on_all")} ",
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  color: Theme.of(context).colorScheme.primary, // Change to desired color
                                ),
                              ),
                              TextSpan(
                                text: "${locale.translate("pages.connections.type.health.instructions.page2.part2")} ",
                                style: Theme.of(context).textTheme.titleLarge!,
                              ),
                              TextSpan(
                                text: "${locale.translate("pages.connections.type.health.instructions.page2.allow")} ",
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  color: Theme.of(context).colorScheme.primary, // Change to desired color
                                ),
                              ),
                              TextSpan(
                                text: Platform.isAndroid
                                    ? locale.translate("pages.connections.type.health.instructions.page2.part3.android")
                                    : locale.translate("pages.connections.type.health.instructions.page2.part3.ios"),
                                style: Theme.of(context).textTheme.titleLarge!,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                child: const Text("Next"),
                onPressed: () async {
                  final manager = _manager;
                  await manager.requestPermissions();
                  await manager.connect();
                  // Already connected skips the check in connect() - the task may add new types.
                  final granted = manager.isConnected && await manager.hasPermissions();

                  if (granted && userTask != null) {
                    // The health probe fetches the data and pauses itself when done.
                    userTask!.backgroundTaskExecutor.resume();
                    userTask!.onDone();
                  }

                  if (!context.mounted) return;
                  // If access still isn't granted (e.g. permanently denied, so the
                  // system sheet no longer appears), guide the user to grant it.
                  if (!granted) {
                    await showPermissionDeniedDialog(
                      context,
                      'pages.connections.type.health.access_denied.message',
                      image: 'assets/instructions/health_permission_allow_all.png',
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataDisclosure(BuildContext context, RPLocalizations locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_outline, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.translate("pages.connections.type.health.instructions.data.title"),
                  style: Theme.of(context).textTheme.labelLarge!,
                ),
                for (final type in _types)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '•  ${healthDataTypeLabel(locale, type)}',
                      style: Theme.of(context).textTheme.labelMedium!,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
