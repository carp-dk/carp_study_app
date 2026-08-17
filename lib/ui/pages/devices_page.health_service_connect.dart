part of carp_study_app;

class HealthServiceConnectPage extends StatelessWidget {
  const HealthServiceConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    DeviceViewModel healthService = bloc.appViewModel.devicesPageViewModel.healthService!;

    return Scaffold(
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
                      _dataDisclosure(context, locale),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "${locale.translate("pages.devices.type.health.instructions.page2.part1")} ",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.grey.shade900),
                            ),
                            TextSpan(
                              text:
                                  "${Platform.isAndroid ? locale.translate("pages.devices.type.health.instructions.page2.android.allow_all") : locale.translate("pages.devices.type.health.instructions.page2.ios.turn_on_all")} ",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: Theme.of(context).colorScheme.primary, // Change to desired color
                              ),
                            ),
                            TextSpan(
                              text: "${locale.translate("pages.devices.type.health.instructions.page2.part2")} ",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.grey.shade900),
                            ),
                            TextSpan(
                              text: "${locale.translate("pages.devices.type.health.instructions.page2.allow")} ",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: Theme.of(context).colorScheme.primary, // Change to desired color
                              ),
                            ),
                            TextSpan(
                              text: Platform.isAndroid
                                  ? locale.translate("pages.devices.type.health.instructions.page2.part3.android")
                                  : locale.translate("pages.devices.type.health.instructions.page2.part3.ios"),
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.grey.shade900),
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
            OutlinedButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text("Next", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () async {
                final manager = healthService.deviceManager;
                await manager.requestPermissions();
                await manager.connect();

                if (!context.mounted) return;
                // If access still isn't granted (e.g. permanently denied, so the
                // system sheet no longer appears), guide the user to grant it.
                if (!healthService.deviceManager.isConnected) {
                  await showDialog<void>(context: context, builder: (context) => _accessDeniedDialog(context, locale));
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _accessDeniedDialog(BuildContext context, RPLocalizations locale) => AlertDialog(
    title: Text(locale.translate("pages.devices.type.health.access_denied.title")),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.translate("pages.devices.type.health.access_denied.message")),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/instructions/health_permission_allow_all.png'),
          ),
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
  );

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
            child: Text(
              locale.translate("pages.devices.type.health.instructions.data.title"),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
