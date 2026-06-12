part of carp_study_app;

/// The home page of the app.
///
/// Shown once the onboarding process is done.
class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({required this.child, super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _setupDone = false;
  bool _setupInFlight = false;

  @override
  void initState() {
    super.initState();
    // Re-run setup when bloc notifies (e.g. after consent submission).
    bloc.addListener(_onBlocChanged);
  }

  @override
  void dispose() {
    bloc.removeListener(_onBlocChanged);
    super.dispose();
  }

  void _onBlocChanged() {
    _maybeRunSetup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeRunSetup();
  }

  Future<void> _maybeRunSetup() async {
    if (_setupDone || _setupInFlight || !mounted) return;
    if (!bloc.hasStudyBeenDeployed) return;

    _setupInFlight = true;
    try {
      // Defer configureStudy (and its OS permission prompts) until consent.
      if (!await bloc.hasInformedConsentBeenAccepted) {
        if (!mounted) return;
        final loc = GoRouterState.of(context).matchedLocation;
        if (loc != InformedConsentPage.route) {
          context.go(InformedConsentPage.route);
        }
        return;
      }

      _setupDone = true;

      // Run setup and HC check in parallel so the HC dialog doesn't gate sensing.
      await Future.wait([
        bloc.configureStudy().whenComplete(() {
          if (mounted) CarpStudyApp.reloadLocale(context);
          bloc.start();
        }),
        if (Platform.isAndroid) _checkHealthConnectInstallation(),
      ]);
    } finally {
      _setupInFlight = false;
    }
  }

  Future<void> _checkHealthConnectInstallation() async {
    bool isInstalled = await bloc.isHealthInstalled();
    if (!isInstalled && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => InstallHealthConnectDialog(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    // Save the localization for the app
    bloc.localization = locale;

    // Listen for user task notification clicked in the OS
    AppTaskController().userTaskEvents.listen((userTask) {
      if (userTask.state == UserTaskState.notified) {
        userTask.onStart();
        if (userTask.hasWidget) {
          _rootNavigatorKey.currentContext?.push('/task/${userTask.id}');
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).extension<CarpColors>()!.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).extension<CarpColors>()!.primary,
        //unselectedItemColor: Theme.of(context).primaryColor.withOpacity(0.8),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.announcement),
            label: locale.translate('app_home.nav_bar_item.about'),
            activeIcon: const Icon(Icons.announcement),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.playlist_add_check),
            label: locale.translate('app_home.nav_bar_item.tasks'),
            activeIcon: const Icon(Icons.playlist_add_check),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard),
            label: locale.translate('app_home.nav_bar_item.data'),
            activeIcon: const Icon(Icons.leaderboard),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.devices_other),
            label: locale.translate('app_home.nav_bar_item.devices'),
            activeIcon: const Icon(Icons.devices_other),
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(StudyPage.route)) {
      return 0;
    }
    if (location.startsWith(TaskListPage.route)) {
      return 1;
    }
    if (location.startsWith(DataVisualizationPage.route)) {
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
        context.go(StudyPage.route);
        break;
      case 1:
        context.go(TaskListPage.route);
        break;
      case 2:
        context.go(DataVisualizationPage.route);
        break;
      case 3:
        context.go(DeviceListPage.route);
        break;
      case -1:
        context.go(CarpStudyAppState.homeRoute);
        break;
    }
  }
}
