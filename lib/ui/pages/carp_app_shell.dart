part of carp_study_app;

/// The bottom navigation bar and the current tab - the router gates what
/// reaches it, so by here the user is signed in, has a study, and has consented.
class CarpAppShell extends StatefulWidget {
  final HomePageViewModel model;
  final Widget child;
  const CarpAppShell({required this.model, required this.child, super.key});

  @override
  CarpAppShellState createState() => CarpAppShellState();
}

class CarpAppShellState extends State<CarpAppShell> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(child: widget.child),
      // Nothing to show until the study loads, so keep the tabs inert and dimmed.
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) => IgnorePointer(
          ignoring: !widget.model.isLoaded,
          child: Opacity(opacity: widget.model.isLoaded ? 1 : 0.4, child: _navigationBar(context, locale)),
        ),
      ),
    );
  }

  // Tasks and Connections are off once the study is stopped.
  static const _stoppedTabs = {1, 3};
  bool _isDisabled(int index) => widget.model.isStopped && _stoppedTabs.contains(index);
  Color? _iconColor(int index) => _isDisabled(index) ? Colors.grey.shade300 : null;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_leaveDisabledTab);
  }

  @override
  void dispose() {
    widget.model.removeListener(_leaveDisabledTab);
    super.dispose();
  }

  // Stopped while on a disabled tab - go back home.
  void _leaveDisabledTab() {
    if (mounted && _isDisabled(_calculateSelectedIndex(context))) context.go(HomePage.route);
  }

  Widget _navigationBar(BuildContext context, RPLocalizations locale) => BottomNavigationBar(
    backgroundColor: Colors.white,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Theme.of(context).colorScheme.primary,
    items: <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: locale.translate('app_home.nav_bar_item.home'),
        activeIcon: const Icon(Icons.home),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.playlist_add_check, color: _iconColor(1)),
        label: locale.translate('app_home.nav_bar_item.tasks'),
        activeIcon: const Icon(Icons.playlist_add_check),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.leaderboard),
        label: locale.translate('app_home.nav_bar_item.statistics'),
        activeIcon: const Icon(Icons.leaderboard),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.devices_other, color: _iconColor(3)),
        label: locale.translate('app_home.nav_bar_item.connections'),
        activeIcon: const Icon(Icons.devices_other),
      ),
    ],
    currentIndex: _calculateSelectedIndex(context),
    onTap: (int idx) => _isDisabled(idx) ? null : _onItemTapped(idx, context),
  );

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
