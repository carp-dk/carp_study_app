part of carp_study_app;

class StudyDetailsPage extends StatelessWidget {
  static const String route = '/study_details';
  final StudyPageViewModel model;
  StudyDetailsPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).extension<RPColors>()!.backgroundGray,
      body: SafeArea(
        child: Container(
          color: Theme.of(context).extension<RPColors>()!.backgroundGray,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18),
                child: const CarpAppBar(hasProfileIcon: true),
              ),
              Row(
                children: [
                  IconButton(
                    padding: const EdgeInsets.only(
                        left: 26, right: 10, top: 16, bottom: 16),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).extension<RPColors>()!.grey600,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(CarpStudyAppState.homeRoute);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(locale.translate(model.title),
                        style: aboutCardTitleStyle.copyWith(
                            color: Theme.of(context)
                                .extension<RPColors>()!
                                .primary)),
                  ),
                ],
              ),
              Flexible(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final screenWidth = MediaQuery.of(context).size.height;
                        return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: screenHeight,
                              maxHeight: screenWidth,
                            ),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: model.image,
                            ));
                      }),
                    ),
                    _buildSectionCard(
                      context,
                      [
                        _buildActionListTile(
                          context: context,
                          leading: Icon(Icons.mail,
                              color: Theme.of(context)
                                  .extension<RPColors>()!
                                  .primary),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: CACHET.GREY_6),
                          title: locale.translate('pages.profile.contact'),
                          onTap: () async {
                            _sendEmailToContactResearcher(
                              locale.translate(model.responsibleEmail),
                              'Support for study: ${locale.translate(model.title)} - User: ${model.responsibleName}',
                            );
                          },
                        ),
                        _buildActionListTile(
                            context: context,
                            leading: Icon(Icons.policy,
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .primary),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: CACHET.GREY_6),
                            title:
                                locale.translate('pages.about.study.privacy'),
                            onTap: () async {
                              try {
                                await launchUrl(Uri.parse(
                                    locale.translate(model.privacyPolicyUrl)));
                              } catch (error) {
                                warning(
                                    "Could not launch study description URL - ${locale.translate(model.privacyPolicyUrl)}");
                              }
                            }),
                        _buildActionListTile(
                          context: context,
                          leading: Icon(Icons.public,
                              color: Theme.of(context)
                                  .extension<RPColors>()!
                                  .primary),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: CACHET.GREY_6),
                          title: locale.translate('pages.about.study.website'),
                          onTap: () async {
                            try {
                              await launchUrl(Uri.parse(
                                  locale.translate(model.studyDescriptionUrl)));
                            } catch (error) {
                              warning(
                                  "Could not launch study description URL - ${locale.translate(model.studyDescriptionUrl)}");
                            }
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.translate('widgets.study_card.responsible'),
                            style: studyDetailsInfoTitle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                            child: Text(
                              locale.translate(model.responsibleName),
                              style: studyDetailsInfoMessage.copyWith(
                                  color: Theme.of(context)
                                      .extension<RPColors>()!
                                      .grey700),
                            ),
                          ),
                          Text(
                            locale.translate(
                                'widgets.study_card.participant_role'),
                            style: studyDetailsInfoTitle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                            child: Text(
                              locale.translate(model.participantRole),
                              style: studyDetailsInfoMessage.copyWith(
                                  color: Theme.of(context)
                                      .extension<RPColors>()!
                                      .grey700),
                            ),
                          ),
                          Text(
                            locale.translate('widgets.study_card.device_role'),
                            style: studyDetailsInfoTitle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                            child: Text(
                              locale.translate(model.deviceRole),
                              style: studyDetailsInfoMessage.copyWith(
                                  color: Theme.of(context)
                                      .extension<RPColors>()!
                                      .grey700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Theme.of(context).extension<RPColors>()!.grey300,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.translate(
                                'widgets.study_card.study_description'),
                            style: studyDetailsInfoTitle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                            child: Text(
                              locale.translate(model.description),
                              style: studyDetailsInfoMessage.copyWith(
                                  color: Theme.of(context)
                                      .extension<RPColors>()!
                                      .grey700),
                            ),
                          ),
                          Text(
                            locale
                                .translate('widgets.study_card.study_purpose'),
                            style: studyDetailsInfoTitle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                            child: Text(
                              locale.translate(model.purpose),
                              style: studyDetailsInfoMessage.copyWith(
                                  color: Theme.of(context)
                                      .extension<RPColors>()!
                                      .grey700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).extension<RPColors>()!.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: ListTile.divideTiles(
            context: context,
            tiles: children,
            color: Theme.of(context).extension<RPColors>()!.grey300,
          ).toList(),
        ),
      ),
    );
  }

// Helper method to build a ListTile for actions with an icon
  Widget _buildActionListTile({
    required BuildContext context,
    required Icon leading,
    required String title,
    Icon? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: leading,
      title: Text(title,
          style: profileActionStyle.copyWith(
              color: Theme.of(context).extension<RPColors>()!.grey900)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }

  // Sends and email to the researcher with the name of the study + user id
  void _sendEmailToContactResearcher(String email, String subject) async {
    final url = Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: {'subject': subject})
        .toString()
        .replaceAll("+", "%20");
    try {
      await launchUrl(Uri.parse(url));
    } finally {}
  }
}
