part of carp_study_app;

class EnableInternetConnectionDialog extends StatelessWidget {
  const EnableInternetConnectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.symmetric(vertical: 4),
      insetPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      title: DialogTitle(title: "pages.login.internet_connection.enable_internet_connections.title"),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: (() {
          switch (OpenSettingsPlus.shared) {
            case OpenSettingsPlusAndroid():
              return enableInternetConnectionInstructionsAndroid(context);
            case OpenSettingsPlusIOS():
              return enableInternetConnectionInstructionsIOS(context);
          }
        }()),
      ),
    );
  }

  Widget enableInternetConnectionInstructionsAndroid(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  locale.translate("pages.login.internet_connection.enable_internet_connections.general_message"),
                  style: fs16fw400,
                  textAlign: TextAlign.justify,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    locale.translate("pages.login.internet_connection.enable_internet_connections.wifi_message"),
                    style: fs16fw400,
                    textAlign: TextAlign.justify,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Image(
                    image: AssetImage(
                      'assets/instructions/${Localizations.localeOf(context).languageCode}/enable_wifi_android.png',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    locale.translate("pages.login.internet_connection.enable_internet_connections.mobile_data_message"),
                    style: fs16fw400,
                    textAlign: TextAlign.justify,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Image(
                    image: AssetImage(
                      'assets/instructions/${Localizations.localeOf(context).languageCode}/enable_mobile_data_android.png',
                    ),
                  ),
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
                onPressed: () {
                  Navigator.of(context).pop();
                  OpenSettingsPlusAndroid().wifi();
                },
                child: Text(locale.translate('pages.enable_connection.wifi')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  OpenSettingsPlusAndroid().dataUsage();
                },
                child: Text(locale.translate('pages.enable_connection.data')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget enableInternetConnectionInstructionsIOS(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  locale.translate("pages.login.internet_connection.enable_internet_connections.general_message"),
                  style: fs16fw400,
                  textAlign: TextAlign.justify,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    locale.translate("pages.login.internet_connection.enable_internet_connections.wifi_message"),
                    style: fs16fw400,
                    textAlign: TextAlign.justify,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Image(
                    image: AssetImage(
                      'assets/instructions/${Localizations.localeOf(context).languageCode}/enable_wifi_ios.png',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        locale.translate(
                          "pages.login.internet_connection.enable_internet_connections.mobile_data_message",
                        ),
                        style: fs16fw400,
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Image(
                    image: AssetImage(
                      'assets/instructions/${Localizations.localeOf(context).languageCode}/enable_mobile_data_ios.png',
                    ),
                  ),
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
                onPressed: () {
                  OpenSettingsPlusIOS().wifi();
                },
                child: Text(locale.translate('pages.enable_connection.wifi')),
              ),
              TextButton(
                onPressed: () {
                  OpenSettingsPlusIOS().cellular();
                },
                child: Text(locale.translate('pages.enable_connection.data')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
