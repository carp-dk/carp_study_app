part of carp_study_app;

class InvitationListPage extends StatefulWidget {
  static const String route = '/invitations';
  final InvitationsViewModel model;
  const InvitationListPage({super.key, required this.model});

  @override
  State<InvitationListPage> createState() => _InvitationListPageState();
}

class _InvitationListPageState extends State<InvitationListPage> {
  @override
  void initState() {
    super.initState();
    widget.model.ensureInvitationsLoaded();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: widget.model.loadInvitations,
        child: ListenableBuilder(
          listenable: widget.model,
          builder: (context, _) {
            Widget child;
            if (widget.model.isLoading) {
              child = const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            } else {
              final invitations = widget.model.invitations;
              child = SliverFixedExtentList(
                itemExtent: 150,
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Container(child: InvitationMaterial(invitation: invitations[index]));
                }, childCount: invitations.length),
              );
            }

            return CustomScrollView(
              // Always scrollable so pull-to-refresh still works when there's
              // zero or one invitation and the content doesn't fill the screen.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(title: const CarpAppBar(), centerTitle: true, pinned: true, scrolledUnderElevation: 0),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: IntrinsicHeight(
                      child: Stack(
                        children: [
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () => widget.model.signOut(),
                            ),
                          ),
                          Center(
                            child: Text(
                              locale.translate('invitation.invitations'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        locale.translate('invitation.subtitle'),
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            );
          },
        ),
      ),
    );
  }
}

class InvitationMaterial extends StatelessWidget {
  final ActiveParticipationInvitation invitation;

  const InvitationMaterial({super.key, required this.invitation});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return StudiesMaterial(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          context.push('${InvitationDetailsPage.route}/${invitation.studyDeploymentId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                invitation.invitation.name,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w600)
                    .copyWith(color: const Color(0xff006398), overflow: TextOverflow.ellipsis),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: locale.translate('invitation_list.roles_in_the_study.description'),
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    TextSpan(
                      text: invitation.participantRoleName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                invitation.invitation.description ?? '',
                maxLines: 2,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(color: Colors.grey.shade900, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
