import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/routes.dart';
import 'package:carp_study_app/features/study/home_view_model.dart';
import 'package:carp_study_app/shared/widgets/carp_app_bar.dart';

/// The fixed app bar and bottom navigation bar, with the current tab between them -
/// only the tab transitions. The router gates what reaches it, so by here the
/// user is signed in, has a study, and has consented.
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
      body: SafeArea(
        child: Column(
          children: [
            const CarpAppBar(hasProfileIcon: true),
            Expanded(child: widget.child),
          ],
        ),
      ),
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
    if (mounted && _isDisabled(_calculateSelectedIndex(context))) context.go(Routes.home);
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
    if (location.startsWith(Routes.home)) {
      return 0;
    }
    if (location.startsWith(Routes.tasks)) {
      return 1;
    }
    if (location.startsWith(Routes.statistics)) {
      return 2;
    }
    if (location.startsWith(Routes.connections)) {
      return 3;
    }
    return -1;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.tasks);
        break;
      case 2:
        context.go(Routes.statistics);
        break;
      case 3:
        context.go(Routes.connections);
        break;
      case -1:
        context.go(Routes.root);
        break;
    }
  }
}
