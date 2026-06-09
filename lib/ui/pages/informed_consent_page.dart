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
  bool _submitted = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 2), () {
      if (mounted && !_submitted) {
        context.go(CarpStudyAppState.homeRoute);
      }
    });
  }

  Future<void> resultCallback(RPTaskResult result) async {
    _submitted = true;
    _timeout?.cancel();
    await widget.model.informedConsentHasBeenAccepted(result);
    if (!mounted) return;
    context.go(CarpStudyAppState.homeRoute);
  }

  @override
  void dispose() {
    _timeout?.cancel();
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
        future: widget.model.getInformedConsent(localization.locale).then(
          (document) async {
            if (document == null && !_submitted) {
              _submitted = true;
              _timeout?.cancel();
              await bloc.informedConsentHasBeenAccepted();
              if (mounted) context.go(CarpStudyAppState.homeRoute);
            }
            return document;
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            _timeout?.cancel();
            return RPUITask(
              task: snapshot.data!,
              onSubmit: resultCallback,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
