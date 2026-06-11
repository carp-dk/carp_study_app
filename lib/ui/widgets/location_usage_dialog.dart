part of carp_study_app;

class LocationUsageDialog {
  Widget build(BuildContext context, String message) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    final AlertDialog locationUsageDialog = AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/icons/location.png",
            width: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.height * 0.15,
          ),
          Text(locale.translate("dialog.location.permission"), style: fs20fw700),
        ],
      ),
      contentPadding: const EdgeInsets.all(15),
      insetPadding: const EdgeInsets.all(30),
      content: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale.translate(message),
                style: fs16fw400,
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Permission.locationWhenInUse.request().then((value) => context.pop(true));
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Theme.of(context).primaryColor),
            foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimary),
          ),
          child: Text(
            locale.translate("dialog.location.continue"),
          ),
        ),
      ],
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: locationUsageDialog,
          ),
        ],
      ),
    );
  }
}
