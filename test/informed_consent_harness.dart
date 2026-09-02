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

  @override
  RPOrderedTask? get informedConsent => _document;

  // The real one loads the document through the global bloc.
  @override
  Future<RPOrderedTask?> getInformedConsent() async => _document;

  var rejected = false;
  var uploads = 0;

  /// Stands in for the CAWS round trip - the delay is what makes a second
  /// submit land while the first is still in flight.
  @override
  Future<void> upload(RPTaskResult result) async {
    uploads++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (uploadFails) throw Exception('no connection');
  }

  // The real one leaves the study, which needs a configured bloc.
  @override
  Future<void> reject() async => rejected = true;
}

/// The consent page under a router with the redirect that gates it.
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
    initialLocation: InformedConsentPage.route,
    refreshListenable: refresh ?? ChangeNotifier(),
    redirect: (context, state) async {
      // The app's consent gate, in the one form that matters here.
      if (await model.needsSigning()) return InformedConsentPage.route;
      if (state.matchedLocation == InformedConsentPage.route) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: InformedConsentPage.route,
        builder: (context, state) => InformedConsentPage(model: model),
      ),
      GoRoute(path: '/home', builder: (context, state) => const Text('home')),
    ],
  ),
);
