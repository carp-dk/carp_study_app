part of carp_study_app;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class CarpStudyApp extends StatefulWidget {
  const CarpStudyApp({super.key});

  /// Reload language translations and re-build the entire app.
  static void reloadLocale(BuildContext context) async {
    CarpAppState? state = context.findAncestorStateOfType<CarpAppState>();
    state?.reloadLocale();
  }

  @override
  CarpAppState createState() => CarpAppState();
}

class CarpAppState extends State<CarpStudyApp> {
  /// The landing page once the onboarding process is done.
  static const String homeRoute = '/';

  /// Reload language translations and re-build the entire app.
  void reloadLocale() => setState(() => rpLocalizationsDelegate.reload());

  // State-driven routing: a bloc change refreshes the router, which re-redirects.
  final GoRouter _router = GoRouter(
    initialLocation: homeRoute,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: bloc,
    errorBuilder: (context, state) => const ErrorPage(),
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      // 1) Not authenticated → login page.
      if (AppConfig.deploymentMode != DeploymentMode.local && !bloc.auth.isAuthenticated) {
        return LoginPage.route;
      }

      // 2) No study → the invitation list (or its details page).
      if (!bloc.study.hasStudy) {
        if (loc == InvitationListPage.route || loc.startsWith('${InvitationDetailsPage.route}/')) {
          return null;
        }
        return InvitationListPage.route;
      }

      // 4) Fully onboarded.
      return null;
    },
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) => CarpAppShell(
          model: bloc.appViewModel.homePageViewModel,
          consentModel: bloc.appViewModel.informedConsentViewModel,
          child: child,
        ),
        routes: [
          // Just a landing slot - the redirect above moves the user on.
          GoRoute(path: homeRoute, parentNavigatorKey: _shellNavigatorKey, redirect: (_, _) => HomePage.route),
          GoRoute(
            path: HomePage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: HomePage(model: bloc.appViewModel.homePageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: TaskListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: TaskListPage(model: bloc.appViewModel.taskListPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          // /study is a legacy alias for the Home tab.
          GoRoute(path: StudyPage.route, parentNavigatorKey: _shellNavigatorKey, redirect: (_, _) => HomePage.route),
          GoRoute(
            path: StatisticsPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: StatisticsPage(bloc.appViewModel.statisticsViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: DeviceListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeviceListPage(model: bloc.appViewModel.devicesPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
        ],
      ),
      // Profile slides in full-screen over the shell, so: root navigator.
      GoRoute(
        path: ProfilePage.route,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProfilePage(bloc.appViewModel.profilePageViewModel),
          transitionsBuilder: slideInFromRightAnimation,
        ),
      ),
      GoRoute(
        path: StudyAboutPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StudyAboutPage(model: bloc.appViewModel.studyPageViewModel),
      ),
      GoRoute(
        path: ParticipantDataPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ParticipantDataPage(model: bloc.appViewModel.participantDataPageViewModel),
      ),
      GoRoute(
        path: '/task/:taskId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          final task = AppTaskController().getUserTask(taskId);
          return task?.widget ?? const ErrorPage();
        },
      ),
      GoRoute(
        path: LoginPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LoginPage(model: bloc.appViewModel.loginViewModel),
      ),
      GoRoute(
        path: '${MessageDetailsPage.route}/:messageId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MessageDetailsPage(messageId: state.pathParameters['messageId'] ?? ''),
      ),
      GoRoute(
        path: '${InvitationDetailsPage.route}/:invitationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => InvitationDetailsPage(
          model: bloc.appViewModel.invitationsListViewModel,
          invitationId: state.pathParameters['invitationId'] ?? '',
        ),
      ),
      GoRoute(
        path: InvitationListPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => InvitationListPage(model: bloc.appViewModel.invitationsListViewModel),
      ),
    ],
    debugLogDiagnostics: true,
  );

  /// RP translations: local language assets plus those downloaded from CARP.
  final RPLocalizationsDelegate rpLocalizationsDelegate = _AppLocalizationsDelegate(
    loaders: [const AssetLocalizationLoader(), bloc.resources.localizationLoader],
  );

  AppState _previousBlocState = bloc.state;
  String? _previousDeploymentId = bloc.study.study?.studyDeploymentId;

  @override
  void initState() {
    super.initState();
    bloc.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    bloc.removeListener(_onAppStateChanged);
    super.dispose();
  }

  /// Re-load translations when a study is set or configured - both add new ones.
  void _onAppStateChanged() {
    final configured = bloc.state == AppState.configured;
    final deploymentId = bloc.study.study?.studyDeploymentId;

    if (mounted &&
        ((configured && _previousBlocState != AppState.configured) || deploymentId != _previousDeploymentId)) {
      reloadLocale();
    }

    _previousBlocState = bloc.state;
    _previousDeploymentId = deploymentId;
  }

  @override
  Widget build(BuildContext context) {
    // Apply system overlay style after frame so Theme.of(context) is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    });
    return MaterialApp.router(
      scaffoldMessengerKey: bloc.scaffoldKey,
      supportedLocales: const [Locale('en'), Locale('da'), Locale('es')],
      localizationsDelegates: [
        // Research Package translations
        rpLocalizationsDelegate,
        // Built-in localization of basic text for Cupertino widgets
        GlobalCupertinoLocalizations.delegate,
        // Built-in localization of basic text for Material widgets
        GlobalMaterialLocalizations.delegate,
        // Built-in localization for text direction LTR/RTL
        GlobalWidgetsLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            Intl.defaultLocale = supportedLocale.languageCode;
            return supportedLocale;
          }
        }
        return supportedLocales.first; // default to EN
      },
      locale: AppConfig.localization?.locale,
      theme: carpTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: true,
      routerConfig: _router,
    );
  }
}

/// Loads the RP translations into [AppConfig], where non-UI layers read them.
class _AppLocalizationsDelegate extends RPLocalizationsDelegate {
  _AppLocalizationsDelegate({required super.loaders});

  @override
  Future<RPLocalizations> load(Locale locale) async {
    final localizations = await super.load(locale);
    AppConfig.localization = localizations;
    return localizations;
  }
}

/// Fade between bottom-nav tabs: the incoming page fades and gently scales in.
Widget bottomNavigationBarAnimation(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final fade = CurveTween(curve: Curves.easeOut).animate(animation);
  return FadeTransition(
    opacity: fade,
    child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(fade), child: child),
  );
}

/// Slide a full-screen page in from the right, as used for the profile page.
Widget slideInFromRightAnimation(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
  return SlideTransition(position: animation.drive(tween), child: child);
}
