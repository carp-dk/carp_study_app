part of carp_study_app;

/// The consent document, shown inline by [CarpAppShell] - pushed as a route it
/// would be replayed on top of the app by any router refresh.
class InformedConsentPage extends StatefulWidget {
  final InformedConsentViewModel model;

  const InformedConsentPage({required this.model, super.key});

  @override
  State<InformedConsentPage> createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  /// Recording the signature - a second DONE would start a second upload.
  bool _accepting = false;

  Future<void> _accept(RPTaskResult result) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      // Accepting flips the status, which swaps this page for the app.
      await widget.model.accept(result);
    } catch (error) {
      // Never reached CAWS, so the user is not consented - say so and leave.
      warning('$runtimeType - could not record informed consent - $error');
      if (mounted) setState(() => _accepting = false);
      if (mounted) await _showFailure();
      await widget.model.reject();
    }
  }

  Future<void> _showFailure() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final locale = RPLocalizations.of(context);
      return AlertDialog(
        content: Text(locale?.translate('pages.informed_consent.upload_failed') ?? ''),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    // The shell loads the document before showing this page.
    final document = widget.model.informedConsent;
    if (document == null) return const ErrorPage();

    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Stack(
            children: [
              RPUITask(
                // This page's lifetime is the shell's to end, not the task's.
                task: document..closeAfterFinished = false,
                onSubmit: _accept,
                // Declining leaves the study - the router then shows invitations.
                onCancel: (_) {
                  unawaited(widget.model.reject());
                },
              ),
              // Block the document while uploading, so it can't be signed twice.
              if (_accepting)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
