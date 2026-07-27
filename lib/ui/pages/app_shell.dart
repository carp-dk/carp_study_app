part of carp_study_app;

/// The app shell shown once onboarding is done: a [Scaffold] hosting the
/// bottom navigation bar and the current tab (via the [ShellRoute] child).
///
/// All setup orchestration (consent gating, study configuration, starting
/// sensing) is owned by the [AppBloc] and the router redirect - not this page.
class CarpAppShell extends StatefulWidget {
  final HomePageViewModel model;
  final Widget child;
  const CarpAppShell({required this.model, required this.child, super.key});

  @override
  CarpAppShellState createState() => CarpAppShellState();
}

class CarpAppShellState extends State<CarpAppShell> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).extension<CarpColors>()!.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).extension<CarpColors>()!.primary,
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
            icon: const Icon(Icons.devices_other),
            label: locale.translate('app_home.nav_bar_item.connections'),
            activeIcon: const Icon(Icons.devices_other),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard),
            label: locale.translate('app_home.nav_bar_item.statistics'),
            activeIcon: const Icon(Icons.leaderboard),
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
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
    if (location.startsWith(DeviceListPage.route)) {
      return 2;
    }
    if (location.startsWith(DataVisualizationPage.route)) {
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
        context.go(DeviceListPage.route);
        break;
      case 3:
        context.go(DataVisualizationPage.route);
        break;
      case -1:
        context.go(CarpAppState.homeRoute);
        break;
    }
  }
}
