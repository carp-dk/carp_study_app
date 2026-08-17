part of carp_study_app;

class InvitationDetailsPage extends StatelessWidget {
  static const String route = '/invitation';
  final String invitationId;
  final InvitationsViewModel model;

  const InvitationDetailsPage({super.key, required this.invitationId, required this.model});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    final invitation = model.getInvitation(invitationId);
    if (invitation == null) {
      return const Scaffold();
    }

    final theme = Theme.of(context);
    final description = invitation.invitation.description;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(InvitationListPage.route);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(locale.translate('invitation.invited_to_study'), style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Study hero.
                    Text(
                      invitation.invitation.name,
                      style: theme.textTheme.headlineSmall!.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    // Invitation message.
                    _SectionCard(
                      title: locale.translate('invitation.message_title'),
                      child: Text(
                        (description == null || description.isEmpty)
                            ? locale.translate('invitation.no_description')
                            : description,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: (description == null || description.isEmpty)
                              ? Colors.grey.shade500
                              : Colors.grey.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Roles.
                    _SectionCard(
                      title: locale.translate('invitation.roles_in_the_study.title'),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: locale.translate('invitation.your_role'),
                            value: invitation.participantRoleName ?? '-',
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.smartphone_outlined,
                            label: locale.translate('invitation.device_role'),
                            value: invitation.deviceRoleName ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // button to accept the invitation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Consent is gated by the app shell, which this navigation
                  // mounts - declining there leaves the study and the router
                  // brings the user back to the invitation list.
                  onPressed: () {
                    model.accept(invitation);
                    context.go(HomePage.route);
                  },
                  child: Text(
                    locale.translate("invitation.accept_invite"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled white card used to group a section of the invitation details.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// An icon + label / value row inside a details section.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: Colors.grey.shade600)),
        ),
        Text(value, style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
