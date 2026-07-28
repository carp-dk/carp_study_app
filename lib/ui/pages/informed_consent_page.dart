part of carp_study_app;

/// The informed consent document, for the user to read and sign.
///
/// Pushed on top of the current page by [CarpAppShell] - never used as a
/// redirect target. That keeps a route below it, so the cancel button in
/// research_package (which pops this route itself) behaves like any other pop
/// and returns "not signed" to the caller. Pops `true` once signed.
class InformedConsentPage extends StatelessWidget {
  static const String route = '/consent';
  final InformedConsentViewModel model;
  const InformedConsentPage({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    // The caller resolves consent - and loads the document - before pushing
    // this page, so a missing one means the route was entered some other way.
    final document = model.informedConsent;
    if (document == null) return const ErrorPage();

    return Scaffold(
      body: RPUITask(
        task: document,
        onSubmit: (result) async {
          await model.accept(result);
          if (context.mounted) context.pop(true);
        },
      ),
    );
  }
}
