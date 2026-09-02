part of carp_study_app;

/// The "About Study" screen (design 2.0): study image, title, full
/// description with a website link, the study roles, and the study purpose.
///
/// Pushed full-screen on the root navigator (outside the app shell).
// ponytail: static labels hardcoded EN like the rest of design 2.0; i18n later.
class StudyAboutPage extends StatelessWidget {
  static const String route = '/study_about';
  final StudyPageViewModel model;
  StudyAboutPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: TextButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go(HomePage.route),
                icon: Icon(Icons.arrow_back_ios, size: 18, color: Theme.of(context).colorScheme.primary),
                label: Text(
                  locale.translate('app_home.nav_bar_item.home'),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  StudiesMaterial(
                    backgroundColor: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 180,
                              child: FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: model.image),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(locale.translate(model.title), style: Theme.of(context).textTheme.titleMedium!),
                          const SizedBox(height: 8),
                          Text(locale.translate(model.description), style: Theme.of(context).textTheme.labelMedium!),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              try {
                                await launchUrl(Uri.parse(locale.translate(model.studyDescriptionUrl)));
                              } catch (error) {
                                warning(
                                  'Could not launch study description URL - ${locale.translate(model.studyDescriptionUrl)}',
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Go to study website',
                                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.open_in_new, size: 16, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _actionCard(
                    context,
                    icon: Icons.policy_outlined,
                    title: locale.translate('pages.profile.privacy'),
                    onTap: () => _launch(model.privacyPolicyUrl),
                  ),
                  _actionCard(
                    context,
                    icon: Icons.mail_outline,
                    title: locale.translate('pages.profile.contact'),
                    onTap: () => _sendEmailToContactResearcher(
                      locale.translate(model.responsibleEmail),
                      'Support for study: ${locale.translate(model.title)} - User: ${model.username}',
                    ),
                  ),
                  _actionCard(
                    context,
                    icon: Icons.download,
                    title: locale.translate('pages.profile.download_consent'),
                    onTap: () => _downloadInformedConsent(context),
                  ),
                  StudiesMaterial(
                    backgroundColor: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                          context,
                          locale.translate('widgets.study_card.responsible'),
                          locale.translate(model.responsibleName),
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                        _field(
                          context,
                          locale.translate('widgets.study_card.participant_role'),
                          locale.translate(model.participantRole),
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                        _field(
                          context,
                          locale.translate('widgets.study_card.device_role'),
                          locale.translate(model.deviceRole),
                        ),
                      ],
                    ),
                  ),
                  StudiesMaterial(
                    backgroundColor: Colors.grey.shade50,
                    child: _field(
                      context,
                      locale.translate('widgets.study_card.study_purpose'),
                      locale.translate(model.purpose),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (error) {
      warning('Could not launch URL - $url');
    }
  }

  /// Sends an email to the researcher with the name of the study + user id.
  Future<void> _sendEmailToContactResearcher(String email, String subject) async {
    final url = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject},
    ).toString().replaceAll("+", "%20");
    await _launch(url);
  }

  /// Fetch the signed consent as PDF and save it via the system save dialog -
  /// the only way to write outside the app sandbox.
  Future<void> _downloadInformedConsent(BuildContext context) async {
    final locale = RPLocalizations.of(context)!;
    final bytes = await model.informedConsentBytes();
    if (!context.mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.translate('pages.profile.download_consent.unavailable'))),
      );
      return;
    }

    final saved = await FilePicker.saveFile(
      dialogTitle: locale.translate('pages.profile.download_consent'),
      fileName: 'informed_consent.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    if (!context.mounted || saved == null) return; // null when cancelled

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(locale.translate('pages.profile.download_consent.saved')),
        action: SnackBarAction(
          label: locale.translate('pages.profile.download_consent.open'),
          // Viewers cannot open the returned content:// URI, so open a cache copy.
          onPressed: () async {
            final copy = File('${(await getTemporaryDirectory()).path}/informed_consent.pdf');
            await copy.writeAsBytes(bytes);
            await OpenFilex.open(copy.path, type: 'application/pdf');
          },
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return StudiesMaterial(
      backgroundColor: Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge!)),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // Same field style as the profile page: grey label over a dark bold value.
  Widget _field(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.labelMedium!),
        ],
      ),
    );
  }
}
