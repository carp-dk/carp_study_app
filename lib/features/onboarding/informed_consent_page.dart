part of carp_study_app;

/// The consent document, for the user to read and sign.
///
/// [RPUITask] pops its own route when the task is cancelled, and again when it
/// finishes - so it is given this page's route to pop, and the redirect decides
/// where that lands.
class InformedConsentPage extends StatefulWidget {
  static const String route = '/consent';
  final InformedConsentViewModel model;

  const InformedConsentPage({required this.model, super.key});

  @override
  State<InformedConsentPage> createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  /// The accept in flight, so the document is blocked while it uploads and a
  /// second DONE cannot start a second upload.
  Future<void>? _acceptFuture;

  void _accept(RPTaskResult result) {
    if (_acceptFuture != null) return;
    final accepting = _acceptAndRoute(result);
    setState(() {
      _acceptFuture = accepting;
    });
  }

  Future<void> _acceptAndRoute(RPTaskResult result) async {
    try {
      await widget.model.accept(result);
      // Consent is given, so the redirect now sends this route to the app.
      if (mounted) context.go(CarpAppState.homeRoute);
    } catch (error) {
      // Never reached CAWS, so the user is not consented - say so and leave.
      warning('$runtimeType - could not record informed consent - $error');
      // Drop the spinner first - the dialog is awaited inside this future.
      if (mounted) setState(() => _acceptFuture = null);
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
    // The redirect resolves consent - which loads the document - before routing
    // here, so a missing one means this page was reached some other way.
    final document = widget.model.informedConsent;
    if (document == null) return const ErrorPage();

    return Scaffold(
      body: Stack(
        children: [
          RPUITask(
            // Leaving is the redirect's call, not the task's.
            task: document,
            onSubmit: _accept,
            // Declining leaves the study - the redirect then shows invitations.
            onCancel: (_) => unawaited(widget.model.reject()),
          ),
          // Block the document while uploading, so it cannot be signed twice.
          FutureBuilder(
            future: _acceptFuture,
            builder: (context, snapshot) => snapshot.connectionState == ConnectionState.waiting
                ? const ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
