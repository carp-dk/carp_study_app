part of carp_study_app;

class EnableBluetoothDialog extends StatelessWidget {
  final DeviceViewModel device;

  const EnableBluetoothDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.symmetric(vertical: 4),
      insetPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      title: const DialogTitle(title: "pages.devices.connection.enable_bluetooth.title"),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: enableBluetoothInstructions(context, device),
      ),
    );
  }

  Widget enableBluetoothInstructions(BuildContext context, DeviceViewModel device) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  locale.translate("pages.devices.connection.enable_bluetooth.message1"),
                  style: Theme.of(context).textTheme.bodyLarge!,
                  textAlign: TextAlign.justify,
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
                Text(
                  locale.translate("pages.devices.connection.enable_bluetooth.message2"),
                  style: Theme.of(context).textTheme.bodyLarge!,
                  textAlign: TextAlign.justify,
                ),
                if (Platform.isAndroid || Platform.isIOS)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Image(
                      image: AssetImage(
                        'assets/instructions/${Localizations.localeOf(context).languageCode}/bluetooth_enable_connections_bar.png',
                      ),
                    ),
                  ),
                Text(
                  locale.translate("pages.devices.connection.enable_bluetooth.message3"),
                  style: Theme.of(context).textTheme.bodyLarge!,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text('Settings'),
                onPressed: () {
                  OpenSettingsPlusIOS().bluetooth();
                  context.canPop() ? context.pop() : null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
