part of carp_study_app;

/// The "About Study" screen (design 2.0): study image, title, full
/// description with a website link, the study roles, and the study purpose.
///
/// Pushed full-screen on the root navigator (outside the app shell).
// ponytail: static labels hardcoded EN like the rest of design 2.0; i18n later.
class StudyDetailsPage extends StatelessWidget {
  static const String route = '/study_details';
  final StudyPageViewModel model;
  StudyDetailsPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    final colors = Theme.of(context).extension<CarpColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: TextButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go(HomePage.route),
                icon: Icon(Icons.arrow_back_ios, size: 18, color: colors.primary),
                label: Text(
                  locale.translate('app_home.nav_bar_item.home'),
                  style: fs16fw600.copyWith(color: colors.primary),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  StudiesMaterial(
                    backgroundColor: colors.grey50!,
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
                          Text(locale.translate(model.title), style: fs18fw700.copyWith(color: colors.grey900)),
                          const SizedBox(height: 8),
                          Text(
                            locale.translate(model.description),
                            style: fs14fw600.copyWith(color: colors.grey900),
                          ),
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
                                  style: fs14fw600.copyWith(
                                    color: colors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.open_in_new, size: 16, color: colors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  StudiesMaterial(
                    backgroundColor: colors.grey50!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(colors, locale.translate('widgets.study_card.responsible'), locale.translate(model.responsibleName)),
                        Divider(height: 1, indent: 16, endIndent: 16, color: colors.grey200),
                        _field(
                          colors,
                          locale.translate('widgets.study_card.participant_role'),
                          locale.translate(model.participantRole),
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: colors.grey200),
                        _field(colors, locale.translate('widgets.study_card.device_role'), locale.translate(model.deviceRole)),
                      ],
                    ),
                  ),
                  StudiesMaterial(
                    backgroundColor: colors.grey50!,
                    child: _field(colors, locale.translate('widgets.study_card.study_purpose'), locale.translate(model.purpose)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same field style as the profile page: grey label over a dark bold value.
  Widget _field(CarpColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: fs12fw600.copyWith(color: colors.grey600)),
          const SizedBox(height: 2),
          Text(value, style: fs14fw600.copyWith(color: colors.grey900)),
        ],
      ),
    );
  }
}
