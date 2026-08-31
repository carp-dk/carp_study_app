import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';

/// A one-step task, so finishing the step finishes the task.
RPOrderedTask _task() => RPOrderedTask(
  identifier: 'consent',
  steps: [RPInstructionStep(identifier: 'welcome', title: 'Welcome', text: 'Please consent.')],
);

class StubConsentViewModel extends InformedConsentViewModel {
  StubConsentViewModel({this.uploadFails = false});

  /// Whether uploading the signed consent to CAWS fails.
  final bool uploadFails;
  final RPOrderedTask _document = _task();
  var accepted = false;

  @override
  RPOrderedTask? get informedConsent => _document;

  @override
  Future<ConsentStatus> hasBeenAccepted() async => ConsentStatus.needsSigning;

  var rejected = false;
  var acceptCalls = 0;

  @override
  Future<void> accept([RPTaskResult? result]) async {
    acceptCalls++;
    // Signing uploads to CAWS before the shell swaps consent out - the delay
    // stands in for that round trip, which is what makes the ordering visible.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (uploadFails) throw Exception('no connection');
    accepted = true;
    await super.accept();
  }

  // The real one leaves the study, which needs a configured bloc.
  @override
  Future<void> reject() async => rejected = true;
}

/// Just the consent page - no shell, no router, for what the page itself owns.
Widget consentPage(InformedConsentViewModel model) => MaterialApp(
  localizationsDelegates: [
    RPLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  home: InformedConsentPage(model: model),
);

/// The shell under a router wired like the real app.
///
/// [refresh] is the router's [refreshListenable] - the real app passes the
/// bloc, so a bloc state change refreshes the router. It defaults to a private
/// notifier because the bloc is a global singleton: a test that leaves it
/// listening would refresh the next test's router.
Widget consentApp(InformedConsentViewModel model, {Listenable? refresh}) => MaterialApp.router(
  localizationsDelegates: [
    RPLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  routerConfig: GoRouter(
    initialLocation: HomePage.route,
    refreshListenable: refresh ?? ChangeNotifier(),
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            CarpAppShell(model: bloc.appViewModel.homePageViewModel, consentModel: model, child: child),
        routes: [
          // The shell's navigation bar requires one of the tab routes to be the
          // current location.
          GoRoute(path: HomePage.route, builder: (context, state) => const Text('home')),
        ],
      ),
    ],
  ),
);
