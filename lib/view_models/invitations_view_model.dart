part of carp_study_app;

/// The view model for the [InvitationListPage] and [InvitationDetailsPage].
class InvitationsViewModel extends ViewModel {
  InvitationsViewModel({AuthService? authService}) : _authService = authService;

  final AuthService? _authService;
  AuthService get _auth => _authService ?? bloc.auth;

  List<ActiveParticipationInvitation>? _invitations;
  Object? _error;

  /// The invitations loaded so far. Empty until [loadInvitations] completes.
  List<ActiveParticipationInvitation> get invitations => _invitations ?? [];

  /// Is the (initial) list of invitations being loaded?
  bool get isLoading => _invitations == null && _error == null;

  bool get hasError => _error != null;

  /// Load / refresh the list of invitations from CAWS.
  Future<void> loadInvitations() async {
    try {
      _invitations = await _auth.getInvitations();
      _error = null;
    } catch (error) {
      warning('$runtimeType - Could not load invitations - $error');
      _error = error;
    }
    notifyListeners();
  }

  ActiveParticipationInvitation getInvitation(String invitationId) =>
      invitations.firstWhere((invitation) => invitation.participation.participantId == invitationId);

  /// Accept [invitation] and make it the active study in the app.
  void accept(ActiveParticipationInvitation invitation) => bloc.setStudyInvitation(invitation);

  /// Sign out and return to the login page.
  Future<void> signOut() => bloc.signOutAndLeaveStudy();
}
