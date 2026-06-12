part of carp_study_app;

class InvitationsViewModel extends ViewModel {
  List<ActiveParticipationInvitation> get invitations => bloc.auth.invitations;

  ActiveParticipationInvitation getInvitation(String invitationId) =>
      invitations.firstWhere((invitation) => invitation.participation.participantId == invitationId);
}
