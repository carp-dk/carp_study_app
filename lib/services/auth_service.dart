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
  Future<List<ActiveParticipationInvitation>> getInvitations() async {
    final all = await _backend.getInvitations();
    return _invitations = all
        .where((invitation) => invitation.assignedDevices?.any((device) => device.device is! Smartphone) != true)
        .toList();
  }

  /// Authenticate using a web view.
  Future<void> authenticate() => _backend.authenticate();

  /// Authenticate anonymously using a magic link.
  Future<void> authenticateWithMagicLink(String uri) => _backend.authenticateWithMagicLink(uri);

  /// Sign out from CAWS and erase all local authentication information.
  Future<void> signOut() => _backend.signOut();
}
