part of carp_study_app;

/// The app shell shown once onboarding is done: a [Scaffold] hosting the
/// bottom navigation bar and the current tab (via the [ShellRoute] child).
///
/// This is also the informed consent gate. The router only mounts the shell
/// once the user is signed in and has a study, so mounting it is exactly the
/// precondition consent still has to be checked against - no matter whether we
/// arrived from a cold start or from accepting an invitation.
class CarpAppShell extends StatefulWidget {
  final HomePageViewModel model;
  final InformedConsentViewModel consentModel;
  final Widget child;
  const CarpAppShell({required this.model, required this.consentModel, required this.child, super.key});

  @override
  CarpAppShellState createState() => CarpAppShellState();
}

class CarpAppShellState extends State<CarpAppShell> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _isInformedConsentAccepted();
    });
  }

  /// Show the informed consent if the study still needs it, then let the study
  /// configure itself. Backing out of consent leaves the study, which sends the
  /// router back to the invitation list.
  Future<void> _isInformedConsentAccepted() async {
    try {
      final status = await widget.consentModel.hasBeenAccepted();
      if (!mounted) return;

      if (status == ConsentStatus.needsSigning) {
        final signed = await context.push<bool>(InformedConsentPage.route);
        if (signed != true) {
          // Declining leaves the study, so there is nothing left to configure.
          await widget.consentModel.reject();
          return;
        }
      }
      // Deploying the study and starting sensing
      unawaited(bloc.tryConfigureStudy());
    } catch (error) {
      warning('$runtimeType - could not resolve informed consent - $error');
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  void _onModelChanged() {
    if (widget.model.shouldPromptHealthConnectInstall && mounted) {
      widget.model.healthConnectPromptShown();
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => InstallHealthConnectDialog(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(child: widget.child),
      // The tabs have nothing to show until the study is loaded - the home page
      // is still a skeleton at that point - so keep them inert and dimmed.
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.model,
        builder: (context, navigationBar) => IgnorePointer(
          ignoring: !widget.model.isLoaded,
          child: Opacity(opacity: widget.model.isLoaded ? 1 : 0.4, child: navigationBar),
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).extension<CarpColors>()!.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: locale.translate('app_home.nav_bar_item.home'),
              activeIcon: const Icon(Icons.home),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.playlist_add_check),
              label: locale.translate('app_home.nav_bar_item.tasks'),
              activeIcon: const Icon(Icons.playlist_add_check),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.leaderboard),
              label: locale.translate('app_home.nav_bar_item.statistics'),
              activeIcon: const Icon(Icons.leaderboard),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.devices_other),
              label: locale.translate('app_home.nav_bar_item.connections'),
              activeIcon: const Icon(Icons.devices_other),
            ),
          ],
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(HomePage.route)) {
      return 0;
    }
    if (location.startsWith(TaskListPage.route)) {
      return 1;
    }
    if (location.startsWith(StatisticsPage.route)) {
      return 2;
    }
    if (location.startsWith(DeviceListPage.route)) {
      return 3;
    }
    return -1;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(HomePage.route);
        break;
      case 1:
        context.go(TaskListPage.route);
        break;
      case 2:
        context.go(StatisticsPage.route);
        break;
      case 3:
        context.go(DeviceListPage.route);
        break;
      case -1:
        context.go(CarpAppState.homeRoute);
        break;
    }
  }
}
