part of carp_study_app;

class AuthorizationDialog extends StatelessWidget {
  final DeviceViewModel device;

  const AuthorizationDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        scrollable: true,
        titlePadding: const EdgeInsets.symmetric(vertical: 4),
        insetPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
        title: const DialogTitle(
          title: "pages.devices.connection.bluetooth_authorization.title",
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: authorizationInstructions(context, device),
        ));
  }

  Widget authorizationInstructions(BuildContext context, DeviceViewModel device) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  locale.translate("pages.devices.connection.bluetooth_authorization.message"),
                  style: fs16fw400,
                  textAlign: TextAlign.justify,
                ),
                Image(
                    image: AssetImage(
                        'assets/instructions/${Localizations.localeOf(context).languageCode}/bluetooth_enable_bar.png'),
                    width: MediaQuery.of(context).size.height * 0.2,
                    height: MediaQuery.of(context).size.height * 0.2),
              ],
            ),
          ),
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                child: Text(locale.translate("cancel")),
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
              ),
              TextButton(
                child: Text(locale.translate("pages.devices.connection.settings")),
                onPressed: () => OpenSettingsPlusIOS().bluetooth(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
