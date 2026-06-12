part of carp_study_app;

class LoginPage extends StatefulWidget {
  static const String route = '/login';
  final LoginViewModel model;
  const LoginPage({required this.model, super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                    showDialog<void>(
                      context: context,
                      builder: (context) => QRViewExample(model: widget.model),
                    );
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
                    final result = await widget.model.signIn();
                    if (!context.mounted) return;
                    if (result == SignInResult.success) {
                      context.go(CarpStudyAppState.homeRoute);
                    } else if (result == SignInResult.offline) {
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
              if (widget.model.isAuthenticated)
                TextButton(
                  onPressed: () {
                    showDialog<bool>(context: context, builder: (context) => const LogoutMessage()).then((value) async {
                      if (value == true) {
                        await widget.model.signOut();
                        if (mounted) setState(() {});
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
