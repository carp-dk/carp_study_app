part of carp_study_app;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class CarpStudyApp extends StatefulWidget {
  const CarpStudyApp({super.key});

  /// Reload language translations and re-build the entire app.
  static void reloadLocale(BuildContext context) async {
    CarpStudyAppState? state =
        context.findAncestorStateOfType<CarpStudyAppState>();
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
    initialLocation: homeRoute,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: bloc,
    errorBuilder: (context, state) {
      debugPrint('[GoRouter ERROR] uri=${state.uri} '
          'matchedLocation=${state.matchedLocation} '
          'error=${state.error}');
      return const ErrorPage();
    },
    redirect: (context, state) async {
      debugPrint('HERE!!!!!!!!!!!!!!!');
      debugPrint('GoRouter redirect called with location: ${state.extra}');
      debugPrint('GoRouter redirect called with uri: ${state.uri}');
      final loc = state.matchedLocation;
      debugPrint('[redirect] loc=$loc auth=${bloc.backend.isAuthenticated} '
          'studyDeployed=${bloc.hasStudyBeenDeployed}');

      if (loc == '/auth/realms/Carp/login-actions/action-token') {
        if (!bloc.backend.isAuthenticated) {
          await bloc.backend.authenticateWithMagicLink(state.uri.toString());
        }
      }

      // // --- DEBUG: hardcoded magic link for local testing ---
      // const debugMagicLink =
      //     "https://study.app.test.carp.dk/auth/realms/Carp/login-actions/action-token?key=eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyZDRkYjcxMy1kMjViLTQ4NWEtOTI2OC05MmI4YzM2NWYwZjIifQ.eyJleHAiOjE4MTI3NTEyMDAsImlhdCI6MTc4MTA4MDA4MiwianRpIjoiYTliMThmMzItYjE5OC00NzY5LWFiOTMtODNkNmQ1MjJlYjdkIiwiaXNzIjoiaHR0cHM6Ly90ZXN0LmNhcnAuZGsvYXV0aC9yZWFsbXMvQ2FycCIsImF1ZCI6Imh0dHBzOi8vdGVzdC5jYXJwLmRrL2F1dGgvcmVhbG1zL0NhcnAiLCJzdWIiOiIxMjFiY2I4OS1mYjNlLTQ4MjMtYjQwZC02NzhjZThiNjZkNzEiLCJ0eXAiOiJleHQtbWFnaWMtbGluayIsImF6cCI6InN0dWRpZXMtYXBwIiwibm9uY2UiOiJhOWIxOGYzMi1iMTk4LTQ3NjktYWI5My04M2Q2ZDUyMmViN2QiLCJyZHUiOiJodHRwczovL3N0dWR5LmFwcC50ZXN0LmNhcnAuZGsvYW5vbnltb3VzIiwicm1lIjpmYWxzZSwicnUiOnRydWV9.HP1Z_cwHQfT-K7P6Bbz87MARPTSIy40Fu8VTUesXbv9kZUxR1LC4NsZxa4h15BauJcKmIYimijMKDpoHfrI3kw&client_id=studies-app";
      // if (Platform.isAndroid && !LocalSettings().referrerUsed) {
      //   LocalSettings().referrerUsed = true;
      //   await bloc.backend.authenticateWithMagicLink(debugMagicLink);
      //   return homeRoute;
      // }
      // // --- END DEBUG ---

      if (Platform.isAndroid && !LocalSettings().referrerUsed) {
        try {
          final referrerDetails = await PlayInstallReferrer.installReferrer;
          final referrer = referrerDetails.installReferrer;
          debugPrint('[redirect] installReferrer: $referrer');
          if (referrer != null && referrer.contains('action-token')) {
            LocalSettings().referrerUsed = true;
            await bloc.backend.authenticateWithMagicLink(referrer);
          }
        } catch (e) {
          debugPrint('Failed to get referrer details: $e');
        }
      }

      // 1) Not authenticated → login page.
      if (bloc.deploymentMode != DeploymentMode.local &&
          !bloc.backend.isAuthenticated) {
        debugPrint('[redirect] → /login (not authenticated)');
        return LoginPage.route;
      }

      // 2) No study deployed → user belongs on the invitation list (or its
      // details page). Anywhere else gets bounced to the list.
      if (!bloc.hasStudyBeenDeployed) {
        if (loc == InvitationListPage.route ||
            loc.startsWith('${InvitationDetailsPage.route}/')) {
          debugPrint('[redirect] → null (already on invitation route)');
          return null;
        }
        debugPrint('[redirect] → /invitations (no study)');
        return InvitationListPage.route;
      }

      // 3) Fully onboarded.
      debugPrint('[redirect] → null (fully onboarded)');
      return null;
    },
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            HomePage(child: child),
        routes: [
          // Home is just a landing slot — the top-level redirect always moves
          // the user to the right place based on bloc state.
          GoRoute(
            path: homeRoute,
            parentNavigatorKey: _shellNavigatorKey,
            redirect: (_, __) => StudyPage.route,
          ),
          GoRoute(
            path: TaskListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: TaskListPage(
                model: bloc.appViewModel.taskListPageViewModel,
              ),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: StudyPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: StudyPage(
                model: bloc.appViewModel.studyPageViewModel,
              ),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
            routes: [
              // /study/consent — nested so the parent StudyPage stays mounted
              // underneath. parentNavigatorKey escapes the shell so the bottom
              // nav doesn't bleed through during consent.
              GoRoute(
                path: 'consent',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => InformedConsentPage(
                  model: bloc.appViewModel.informedConsentViewModel,
                ),
              ),
            ],
          ),
          GoRoute(
            path: DataVisualizationPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: DataVisualizationPage(
                  bloc.appViewModel.dataVisualizationPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: DeviceListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: DeviceListPage(),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
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
        builder: (context, state) => StudyDetailsPage(
          model: bloc.appViewModel.studyPageViewModel,
        ),
      ),
      GoRoute(
        path: ParticipantDataPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ParticipantDataPage(
            model: bloc.appViewModel.participantDataPageViewModel),
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
      // Handle external magic-link callbacks from the auth server. The
      // identity provider posts a link like
      // /auth/realms/Carp/login-actions/action-token?key=...
      // We attempt to authenticate using the URI. On
      // success we go to '/', on failure we redirect to the login page.
      GoRoute(
        path: '/auth/realms/Carp/login-actions/action-token',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, __) => homeRoute,
      ),
      GoRoute(
        path: '/anonymous',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, __) => homeRoute,
      ),
      GoRoute(
        path: LoginPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '${MessageDetailsPage.route}/:messageId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MessageDetailsPage(
            messageId: state.pathParameters['messageId'] ?? ''),
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
        builder: (context, state) => InvitationListPage(
            model: bloc.appViewModel.invitationsListViewModel),
      ),
    ],
    debugLogDiagnostics: true,
  );

  /// Research Package translations, incl. both local language assets plus
  /// translations of informed consent and surveys downloaded from CARP
  final RPLocalizationsDelegate rpLocalizationsDelegate =
      RPLocalizationsDelegate(
    loaders: [
      const AssetLocalizationLoader(),
      bloc.localizationLoader,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final studyAppColors = Theme.of(context).extension<StudyAppColors>();

    // Apply system overlay style after frame so Theme.of(context) is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ));
    });
    return MaterialApp.router(
      scaffoldMessengerKey: bloc.scaffoldKey,
      supportedLocales: const [
        Locale('en'),
        Locale('da'),
        Locale('es'),
      ],
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
      locale: bloc.localization?.locale,
      theme: carpTheme.copyWith(
        extensions: [
          carpTheme.extension<CarpColors>()!.copyWith(
                primary: studyAppColors?.primary,
              ),
        ],
      ),
      darkTheme: carpDarkTheme,
      debugShowCheckedModeBanner: true,
      routerConfig: _router,
    );
  }
}

FadeTransition bottomNavigationBarAnimation(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    FadeTransition(
      opacity: animation,
      child: child,
    );
