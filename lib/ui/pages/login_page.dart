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
    final textTheme = Theme.of(context).textTheme;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      locale.translate('pages.login.invited.question'),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locale.translate('pages.login.invited.question_hint'),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(color: textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 24),
                    _ChoiceCard(
                      icon: Icons.qr_code_2,
                      title: locale.translate('pages.login.invited.code.title'),
                      hint: locale.translate('pages.login.invited.code.hint'),
                      primary: true,
                      onTap: () => context.push(CodeSignInPage.route),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      icon: Icons.person_outline,
                      title: locale.translate('pages.login.invited.account.title'),
                      hint: locale.translate('pages.login.invited.account.hint'),
                      primary: false,
                      onTap: _signIn,
                    ),
                    const SizedBox(height: 16),
                  ],
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

  Future<void> _signIn() async {
    final result = await widget.model.signIn();
    if (!mounted) return;
    if (result == SignInResult.success) {
      final invitations = bloc.appViewModel.invitationsListViewModel;
      await invitations.loadInvitations();
      if (!mounted) return;
      context.go(invitations.landingRoute);
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
  }
}

/// Icon + title + one-line hint; filled for the primary choice, outlined otherwise.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = primary ? scheme.onPrimary : scheme.onSurface;
    final child = Row(
      children: [
        Icon(icon, size: 36, color: fg),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: fg),
              ),
              const SizedBox(height: 2),
              Text(hint, style: TextStyle(fontSize: 15, color: fg.withValues(alpha: 0.75))),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: fg),
      ],
    );
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
    return primary
        ? FilledButton(onPressed: onTap, style: style, child: child)
        : OutlinedButton(onPressed: onTap, style: style, child: child);
  }
}
