part of carp_study_app;

class InstallHealthConnectDialog extends StatelessWidget {
  const InstallHealthConnectDialog(BuildContext context, {super.key});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return AlertDialog(
      titlePadding: const EdgeInsets.symmetric(vertical: 4),
      insetPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      title: const DialogTitle(
        title: "pages.about.install_health_connect.title",
      ),
      content: Text(
        locale.translate('pages.about.install_health_connect.description'),
        style: fs16fw400,
        textAlign: TextAlign.justify,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(locale.translate('cancel')),
        ),
        TextButton(
          child: Text(locale.translate('install')),
          onPressed: () async {
            _redirectToHealthConnectPlayStore();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _redirectToHealthConnectPlayStore() async {
    final Uri url = Uri.parse(
        'https://play.google.com/store/apps/details?id=${LocalSettings.healthConnectPackageName}');
    var canLaunch = await canLaunchUrl(url);
    if (canLaunch) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
