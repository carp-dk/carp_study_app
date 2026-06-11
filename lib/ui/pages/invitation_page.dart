part of carp_study_app;

class InvitationDetailsPage extends StatelessWidget {
  static const String route = '/invitation';
  final String invitationId;
  final InvitationsViewModel model;

  const InvitationDetailsPage({
    super.key,
    required this.invitationId,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    var invitation = model.getInvitation(invitationId);

    return Scaffold(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Stack(
                  children: [
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(InvitationListPage.route);
                          }
                        },
                      ),
                    ),
                    Center(
                      child: Text(
                        locale.translate('invitation.invited_to_study'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: StudiesMaterial(
                  backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.translate('invitation.roles_in_the_study.title'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${locale.translate('invitation.roles_in_the_study.description')} ${invitation.participantRoleName}, ${invitation.deviceRoleName}',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: StudiesMaterial(
                    backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 24.0,
                        left: 24.0,
                        top: 16.0,
                        bottom: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invitation.invitation.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22.0,
                                      color: Theme.of(context).extension<CarpColors>()!.primary,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${(locale.translate('pages.profile.study_id'))}: ${invitation.studyDeploymentId}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).extension<CarpColors>()!.grey600,
                                        ),
                                        maxLines: 1,
                                        textScaler: TextScaler.linear(0.9),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    invitation.invitation.description ?? '',
                                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // button to accept the invitation
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xff006398),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: TextButton(
                  onPressed: () {
                    bloc.setStudyInvitation(invitation, context);
                    context.go(StudyPage.route);
                  },
                  child: Text(
                    locale.translate("invitation.accept_invite"),
                    style: const TextStyle(color: Color(0xffffffff), fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
