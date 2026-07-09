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

  /// Have invitations been successfully loaded at least once?
  bool get isLoaded => _invitations != null;

  /// Is the (initial) list of invitations being loaded?
  bool get isLoading => _invitations == null && _error == null;

  bool get hasError => _error != null;

  /// The route to land on after authenticating: the single invitation's
  /// detail if there is exactly one, otherwise the list.
  String get landingRoute => invitations.length == 1
      ? '${InvitationDetailsPage.route}/${invitations.first.participation.participantId}'
      : InvitationListPage.route;

  /// Load / refresh the list of invitations from CAWS. Always hits the
  /// backend - used for sign-in and pull-to-refresh.
  Future<void> loadInvitations() async {
    logApp('InvitationsViewModel.loadInvitations() START');
    try {
      _invitations = await _auth.getInvitations();
      _error = null;
      logApp(
        'InvitationsViewModel.loadInvitations() DONE - ${_invitations!.length} invitation(s): '
        '${_invitations!.map((i) => i.studyDeploymentId).toList()}',
      );
    } catch (error) {
      warning('$runtimeType - Could not load invitations - $error');
      logApp('InvitationsViewModel.loadInvitations() FAILED - $error');
      _error = error;
    }
    notifyListeners();
  }

  /// Load invitations only if not already loaded. Used on entry to the list
  /// page to avoid re-fetching when sign-in just loaded them; pull-to-refresh
  /// calls [loadInvitations] directly to force a refresh.
  Future<void> ensureInvitationsLoaded() async {
    if (isLoaded) return;
    await loadInvitations();
  }

  ActiveParticipationInvitation getInvitation(String invitationId) =>
      invitations.firstWhere((invitation) => invitation.participation.participantId == invitationId);

  /// Accept [invitation] and make it the active study in the app.
  void accept(ActiveParticipationInvitation invitation) {
    logApp('InvitationsViewModel.accept() - deploymentId=${invitation.studyDeploymentId}');
    bloc.setStudyInvitation(invitation);
  }

  /// Sign out and return to the login page.
  Future<void> signOut() => bloc.signOutAndLeaveStudy();

  @override
  void clear() {
    _invitations = null;
    _error = null;
    super.clear();
  }
}
