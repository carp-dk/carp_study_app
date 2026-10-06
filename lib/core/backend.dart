part of carp_study_app;

/// Where the study comes from: sign-in, invitations and informed consent.
/// [CarpBackend] talks to CAWS; [LocalBackend] serves the files in `assets/carp`.
abstract class Backend {
  /// The backend for the current [DeploymentMode].
  factory Backend() => AppConfig.deploymentMode == DeploymentMode.local ? LocalBackend() : CarpBackend();

  /// The URI of the server (or local folder) used in this deployment.
  Uri get uri;

  /// Initialize this backend. Must be called before used.
  Future<void> initialize();

  /// Has the user been authenticated?
  bool get isAuthenticated;

  /// The user authenticated, if any.
  CarpUser? get user;

  /// Authenticate with a username and password.
  Future<void> authenticate();

  /// The magic link belonging to a short sign-in [code], or null if unknown.
  Future<String?> magicLinkForCode(String code);

  /// Authenticate anonymously using a magic link.
  Future<void> authenticateWithMagicLink(String uri);

  /// Sign out and erase all authentication information.
  Future<void> signOut();

  /// The active invitations for this user.
  Future<List<ActiveParticipationInvitation>> getInvitations();

  /// Set the [study] used on this phone.
  set study(SmartphoneStudy study);

  /// Upload the signed informed consent in [consent].
  Future<InformedConsentInput?> uploadInformedConsent(RPTaskResult consent);

  /// The signed informed consent for [role] in [studyDeploymentId], if any.
  Future<InformedConsentInput?> getInformedConsentByRole(String studyDeploymentId, String? role);
}
