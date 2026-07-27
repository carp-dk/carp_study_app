part of carp_study_app;

/// User identity and authentication, wrapping the [CarpBackend] so the rest
/// of the app does not depend on the CAWS SDK types directly.
class AuthService {
  AuthService({CarpBackend? backend}) : _backend = backend ?? CarpBackend();

  final CarpBackend _backend;

  /// Initialize the CAWS backend. Must be called before authentication.
  Future<void> initialize() => _backend.initialize();

  /// Has the user been authenticated?
  bool get isAuthenticated => _backend.isAuthenticated;

  /// Did the user authenticate anonymously (via a magic link / QR code)
  /// rather than a full CAWS login?
  bool get isAnonymous => LocalSettings().isAnonymous;

  /// The signed in user. Returns null if no user is signed in.
  CarpUser? get user => _backend.user;

  /// The username of the signed in user.
  /// Returns an empty string if no user is signed in.
  String get username => user?.username ?? '';

  /// The name used for friendly greeting.
  /// Returns an empty string if no user is signed in.
  String get friendlyUsername => user?.firstName ?? '';

  /// The URI of the CAWS server used in this deployment.
  Uri get serverUri => _backend.uri;

  List<ActiveParticipationInvitation> _invitations = [];

  /// The list of invitations for this user, as last fetched by [getInvitations].
  List<ActiveParticipationInvitation> get invitations => _invitations;

  /// Get / refresh the list of active invitations for this user from CAWS,
  /// keeping only invitations assigned to a smartphone (and not, e.g., a
  /// web browser).
  ///
  /// CAWS returns the invitations in no particular order, so they are sorted
  /// by study name (deployment id as tie-breaker) to keep the list stable
  /// across refreshes.
  Future<List<ActiveParticipationInvitation>> getInvitations() async {
    final all = await _backend.getInvitations();
    _invitations =
        all.where((invitation) => invitation.assignedDevices?.any((device) => device.device is! Smartphone) != true).toList()
          ..sort((a, b) {
            final byName = a.invitation.name.compareTo(b.invitation.name);
            return byName != 0 ? byName : a.studyDeploymentId.compareTo(b.studyDeploymentId);
          });
    _logInvitations(all, _invitations);
    return _invitations;
  }

  /// Dump the identity of every invitation CAWS returned, so entries that look
  /// like duplicates in the UI (same study name) can be told apart by their
  /// deployment / participant / role ids. Filter device logs with
  /// `flutter logs | grep INVITATIONS`.
  void _logInvitations(List<ActiveParticipationInvitation> all, List<ActiveParticipationInvitation> kept) {
    logApp('INVITATIONS - backend returned ${all.length}, kept ${kept.length} after the smartphone filter');
    for (final (index, invitation) in all.indexed) {
      logApp(
        'INVITATIONS - [$index] ${kept.contains(invitation) ? 'KEPT   ' : 'DROPPED'} '
        'name="${invitation.invitation.name}" '
        'studyId=${invitation.studyId} '
        'deploymentId=${invitation.studyDeploymentId} '
        'participantId=${invitation.participantId} '
        'roles=${invitation.participation.assignedRoles.roleNames} '
        'devices=${invitation.assignedDevices?.map((d) => '${d.device.roleName}(${d.device.runtimeType})').toList()}',
      );
    }
    // Same deployment twice means CAWS sent two participations of one deployment;
    // distinct deployments with the same name means the study was deployed twice.
    final deployments = all.map((invitation) => invitation.studyDeploymentId).toList();
    logApp(
      'INVITATIONS - ${deployments.toSet().length} distinct deployment(s) in ${deployments.length} invitation(s), '
      '${all.map((invitation) => invitation.participantId).toSet().length} distinct participant id(s)',
    );
  }

  /// Authenticate using a web view.
  Future<void> authenticate() => _backend.authenticate();

  /// Authenticate anonymously using a magic link.
  Future<void> authenticateWithMagicLink(String uri) => _backend.authenticateWithMagicLink(uri);

  /// Sign out from CAWS and erase all local authentication information.
  Future<void> signOut() => _backend.signOut();
}
