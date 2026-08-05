part of carp_study_app;

class DisconnectionDialog extends StatelessWidget {
  final DeviceViewModel device;

  const DisconnectionDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.symmetric(vertical: 4),
      insetPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      title: const DialogTitle(title: "pages.devices.connection.disconnect_bluetooth.title"),
      content: SizedBox(child: disconnectBluetooth(context, device)),
    );
  }

  Widget disconnectBluetooth(BuildContext context, DeviceViewModel device) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          "${locale.translate("pages.devices.connection.disconnect_bluetooth.message")} ${locale.translate(device.name)}?",
          style: Theme.of(context).textTheme.bodyLarge!,
          textAlign: TextAlign.justify,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              child: Text(locale.translate("cancel")),
              onPressed: () {
                if (context.canPop()) context.pop(false);
              },
            ),
            TextButton(
              onPressed: () {
                if (context.canPop()) context.pop(true);
              },
              child: Text(locale.translate("pages.devices.connection.disconnect_bluetooth.disconnect")),
            ),
          ],
        ),
      ],
    );
  }
}
