part of carp_study_app;

class LoginPage extends StatefulWidget {
  static const String route = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 56),
                  child: Image.asset('assets/carp_logo.png', fit: BoxFit.contain),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                width: MediaQuery.of(context).size.width,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xff006398), borderRadius: BorderRadius.circular(100)),
                child: TextButton(
                  onPressed: () {
                    showDialog<void>(context: context, builder: (context) => QRViewExample());
                  },
                  child: Text(
                    locale.translate("scan"),
                    style: const TextStyle(color: Color(0xffffffff), fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                width: MediaQuery.of(context).size.width,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xff006398), borderRadius: BorderRadius.circular(100)),
                child: TextButton(
                  onPressed: () async {
                    bool isConnected = await bloc.system.checkConnectivity();
                    if (isConnected) {
                      await bloc.auth.initialize();
                      await bloc.auth.authenticate();
                      if (context.mounted) context.go(CarpStudyAppState.homeRoute);
                    } else {
                      showDialog<bool>(
                        context: context,
                        builder: (context) => PopScope(
                          onPopInvokedWithResult: (didPop, result) async {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (didPop && result == true) {
                                Navigator.of(context).pop();
                              }
                            });
                          },
                          child: EnableInternetConnectionDialog(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    locale.translate("pages.login.login"),
                    style: const TextStyle(color: Color(0xffffffff), fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (bloc.auth.isAuthenticated)
                TextButton(
                  onPressed: () {
                    showDialog<bool>(context: context, builder: (context) => const LogoutMessage()).then((value) async {
                      if (value == true) {
                        await bloc.auth.signOut();
                        setState(() {});
                      }
                    });
                  },
                  child: Text(locale.translate('pages.login.logout')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
