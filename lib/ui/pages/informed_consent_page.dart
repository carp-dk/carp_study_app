part of carp_study_app;

class InformedConsentPage extends StatefulWidget {
  static const String route = '/study/consent';
  final InformedConsentViewModel model;
  const InformedConsentPage({super.key, required this.model});

  @override
  InformedConsentState createState() => InformedConsentState();
}

class InformedConsentState extends State<InformedConsentPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Tracks whether the user actually completed consent. Anything else that
  // tears down this page (cancel dialog, system back, programmatic redirect)
  // is treated as "user did not consent" and leaveStudy() is called from
  // dispose(). Set BEFORE awaiting the upload so a router-driven redirect
  // mid-await doesn't get misread as a cancel.
  bool _submitted = false;

  Future<void> resultCallback(RPTaskResult result) async {
    _submitted = true;
    await widget.model.informedConsentHasBeenAccepted(result);
    if (!mounted) return;
    context.go(CarpStudyAppState.homeRoute);
  }

  @override
  void dispose() {
    // Bypassing onCancel entirely is intentional — see issue carp-dk/research.package#168.
    if (!_submitted) {
      bloc.leaveStudy();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations localization = RPLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      body: FutureBuilder<RPOrderedTask?>(
        future: widget.model.getInformedConsent(localization.locale).then((document) async {
          // No consent document configured for this study → mark accepted
          // and navigate to /study. Set _submitted so dispose() doesn't tear
          // the study back down.
          if (document == null && !_submitted) {
            _submitted = true;
            await bloc.informedConsentHasBeenAccepted();
            if (mounted) context.go(CarpStudyAppState.homeRoute);
          }
          return document;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return RPUITask(task: snapshot.data!, onSubmit: resultCallback);
            }
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
