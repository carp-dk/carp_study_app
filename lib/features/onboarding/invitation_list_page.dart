import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/routes.dart';
import 'package:carp_study_app/features/onboarding/invitations_view_model.dart';
import 'package:carp_study_app/shared/widgets/carp_app_bar.dart';
import 'package:carp_study_app/shared/widgets/studies_material.dart';

class InvitationListPage extends StatefulWidget {
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
              child = SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => InvitationMaterial(invitation: invitations[index]),
                  childCount: invitations.length,
                ),
              );
            }

            return CustomScrollView(
              // Always scrollable so pull-to-refresh still works when there's
              // zero or one invitation and the content doesn't fill the screen.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SafeArea(bottom: false, child: CarpAppBar())),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => widget.model.signOut()),
                        Expanded(
                          child: Text(
                            locale.translate('invitation.invitations'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      locale.translate('invitation.subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey.shade600),
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
    final theme = Theme.of(context);
    return StudiesMaterial(
      backgroundColor: Colors.white,
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          context.push('${Routes.invitations}/${invitation.studyDeploymentId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.invitation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${locale.translate('invitation_list.roles_in_the_study.description')}${invitation.participantRoleName ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
