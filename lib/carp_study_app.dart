part of carp_study_app;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class CarpStudyApp extends StatefulWidget {
  const CarpStudyApp({super.key});

  /// Reload language translations and re-build the entire app.
  static void reloadLocale(BuildContext context) async {
    CarpStudyAppState? state = context.findAncestorStateOfType<CarpStudyAppState>();
    state?.reloadLocale();
  }

  @override
  CarpStudyAppState createState() => CarpStudyAppState();
}

class CarpStudyAppState extends State<CarpStudyApp> {
  /// The landing page once the onboarding process is done.
  static const String homeRoute = '/';

  /// Reload language translations and re-build the entire app.
  void reloadLocale() => setState(() => rpLocalizationsDelegate.reload());

  // State-driven routing. Bloc state
  // changes notify the router via refreshListenable, which re-evaluates the
  // redirect at the current location and moves the user automatically.
  final GoRouter _router = GoRouter(
    initialLocation: StudyPage.route,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: bloc,
    errorBuilder: (context, state) => const ErrorPage(),
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      // 1) Not authenticated → login page.
      if (bloc.config.deploymentMode != DeploymentMode.local && !bloc.auth.isAuthenticated) {
        return LoginPage.route;
      }

      // 2) No study selected → user belongs on the invitation list (or its
      // details page). Anywhere else gets bounced to the list.
      if (!bloc.study.hasStudy) {
        if (loc == InvitationListPage.route || loc.startsWith('${InvitationDetailsPage.route}/')) {
          return null;
        }
        return InvitationListPage.route;
      }

      // 3) Study selected but consent known to be pending → consent page.
      // (null means the consent status is still being checked - stay put.)
      if (!bloc.isConfiguring && bloc.consent.isAccepted == false) {
        return loc == InformedConsentPage.route ? null : InformedConsentPage.route;
      }

      // 4) Fully onboarded.
      return null;
    },
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            HomePage(model: bloc.appViewModel.homePageViewModel, child: child),
        routes: [
          // Home is just a landing slot — the top-level redirect always moves
          // the user to the right place based on bloc state.
          GoRoute(path: homeRoute, parentNavigatorKey: _shellNavigatorKey, redirect: (_, _) => StudyPage.route),
          GoRoute(
            path: TaskListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: TaskListPage(model: bloc.appViewModel.taskListPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: StudyPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: StudyPage(model: bloc.appViewModel.studyPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
            routes: [
              // /study/consent — nested so the parent StudyPage stays mounted
              // underneath. parentNavigatorKey escapes the shell so the bottom
              // nav doesn't bleed through during consent.
              GoRoute(
                path: 'consent',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => InformedConsentPage(model: bloc.appViewModel.informedConsentViewModel),
              ),
            ],
          ),
          GoRoute(
            path: DataVisualizationPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: DataVisualizationPage(bloc.appViewModel.dataVisualizationPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: DeviceListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) =>
                const CustomTransitionPage(child: DeviceListPage(), transitionsBuilder: bottomNavigationBarAnimation),
          ),
          GoRoute(
            path: ProfilePage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: ProfilePage(bloc.appViewModel.profilePageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
        ],
      ),
      GoRoute(
        path: StudyDetailsPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StudyDetailsPage(model: bloc.appViewModel.studyPageViewModel),
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

  /// Research Package translations, incl. both local language assets plus
  /// translations of informed consent and surveys downloaded from CARP
  final RPLocalizationsDelegate rpLocalizationsDelegate = _AppLocalizationsDelegate(
    loaders: [const AssetLocalizationLoader(), bloc.resources.localizationLoader],
  );

  StudyAppState _previousBlocState = bloc.state;
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

  /// Re-load translations when a (new) study is set or has been configured,
  /// since both make new study-specific translations available.
  void _onAppStateChanged() {
    final configured = bloc.state == StudyAppState.configured;
    final deploymentId = bloc.study.study?.studyDeploymentId;

    if (mounted &&
        ((configured && _previousBlocState != StudyAppState.configured) || deploymentId != _previousDeploymentId)) {
      reloadLocale();
    }

    _previousBlocState = bloc.state;
    _previousDeploymentId = deploymentId;
  }

  @override
  Widget build(BuildContext context) {
    final studyAppColors = Theme.of(context).extension<StudyAppColors>();

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
      locale: bloc.config.localization?.locale,
      theme: carpTheme.copyWith(
        extensions: [carpTheme.extension<CarpColors>()!.copyWith(primary: studyAppColors?.primary)],
      ),
      darkTheme: carpDarkTheme,
      debugShowCheckedModeBanner: true,
      routerConfig: _router,
    );
  }
}

/// Loads the RP translations and captures the loaded localization in
/// [AppConfig], where non-UI layers (e.g. protocol translation) read it.
class _AppLocalizationsDelegate extends RPLocalizationsDelegate {
  _AppLocalizationsDelegate({required super.loaders});

  @override
  Future<RPLocalizations> load(Locale locale) async {
    final localizations = await super.load(locale);
    AppConfig().localization = localizations;
    return localizations;
  }
}

FadeTransition bottomNavigationBarAnimation(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => FadeTransition(opacity: animation, child: child);
