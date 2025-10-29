part of carp_study_app;

class HealthServiceConnectPage extends StatelessWidget {
  const HealthServiceConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    DeviceViewModel healthServive = bloc.deploymentDevices
        .where((element) =>
            element.deviceManager is OnlineServiceManager &&
            element.type == HealthService.DEVICE_TYPE)
        .first;

    return Scaffold(
      backgroundColor: Theme.of(context).extension<RPColors>()!.grey100,
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18),
                child: const CarpAppBar(),
              ),
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
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "${locale.translate("pages.devices.type.health.instructions.page2.part1")} ",
                              style: healthServiceConnectMessageStyle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900,
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${Platform.isAndroid ? locale.translate("pages.devices.type.health.instructions.page2.android.allow_all") : locale.translate("pages.devices.type.health.instructions.page2.ios.turn_on_all")} ",
                              style: healthServiceConnectMessageStyle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .primary, // Change to desired color
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${locale.translate("pages.devices.type.health.instructions.page2.part2")} ",
                              style: healthServiceConnectMessageStyle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900,
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${locale.translate("pages.devices.type.health.instructions.page2.allow")} ",
                              style: healthServiceConnectMessageStyle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .primary, // Change to desired color
                              ),
                            ),
                            TextSpan(
                              text: Platform.isAndroid
                                  ? locale.translate(
                                      "pages.devices.type.health.instructions.page2.part3.android")
                                  : locale.translate(
                                      "pages.devices.type.health.instructions.page2.part3.ios"),
                              style: healthServiceConnectMessageStyle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900,
                              ),
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
              child: const Text(
                "Next",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).extension<RPColors>()!.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () async {
                await healthServive.deviceManager.requestPermissions();
                await healthServive.deviceManager.connect();

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
