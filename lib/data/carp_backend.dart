part of carp_study_app;

/// Handles a connection to the CAWS backend, including configuring the CAWS [app],
/// authentication, storing study IDs, and uploading informed consent.
///
/// Use as a singleton ` CarpBackend()`.
class CarpBackend {
  /// The URL of the official CARP web site.
  static const String carpWebsiteUrl = "https://carp.dk";

  /// The URL of the CARP Privacy Policy for this app.
  static const String carpPrivacyUrl = "$carpWebsiteUrl/privacy-policy-app";

  /// The URIs of the CARP Web Service (CAWS) host for each [DeploymentMode].
  static const Map<DeploymentMode, String> uris = {
    DeploymentMode.dev: 'dev.carp.dk',
    DeploymentMode.test: 'test.carp.dk',
    DeploymentMode.production: 'carp.computerome.dk',
  };

  static final CarpBackend _instance = CarpBackend._();
  factory CarpBackend() => _instance;
  CarpBackend._() : super() {
    // make sure that the json functions are loaded
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();
  }

  /// The URI of the CAWS server - depending on deployment mode.
  Uri get uri => Uri(
        scheme: 'https',
        host: uris[bloc.deploymentMode],
      );

  /// The URI of the CAWS authentication service.
  ///
  /// Of the form:
  ///    https://dev.carp.dk/auth/realms/Carp/
  Uri get authUri => Uri(
        scheme: 'https',
        host: uris[bloc.deploymentMode],
        pathSegments: [
          'auth',
          'realms',
          'Carp',
        ],
      );

  /// The CAWS app configuration.
  late final CarpApp _app = CarpApp(name: "CAWS @ DTU", uri: uri);

  CarpApp get app => _app;

  /// The authentication configuration
  CarpAuthProperties get authProperties => CarpAuthProperties(
        authURL: uri,
        clientId: 'studies-app',
        redirectURI: Uri.parse('carp-studies-auth://auth'),
        anonymousRedirectURI: Uri.parse('carp-studies:/anonymous'),
        // For authentication at CAWS the path is '/auth/realms/Carp'
        discoveryURL: uri.replace(pathSegments: [
          'auth',
          'realms',
          'Carp',
        ]),
      );

  /// Initialize this backend. Must be called before used.
  Future<void> initialize() async {
    info('$runtimeType - initializing');

    await CarpAuthService().configure(authProperties);
    CarpService().configure(app);

    // check if there is a user stored locally on the phone
    if (user != null) {
      info('$runtimeType - User stored locally - user: $user');
      CarpAuthService().currentUser = user;
      if (oauthToken!.hasExpired) {
        try {
          await refresh();
        } catch (error) {
          CarpAuthService().currentUser = null;
          warning('$runtimeType - Failed to refresh access token - $error');
        }
      }
    }

    CarpParticipationService().configureFrom(CarpService());
    CarpDeploymentService().configureFrom(CarpService());

    info('$runtimeType initialized - app: $app');
  }

  /// Authenticate using a web view.
  Future<void> authenticate() async {
    try {
      user = await CarpAuthService().authenticate();
      LocalSettings().isAnonymous = false;
      info('$runtimeType - User authenticated - user: $user');
    } catch (error) {
      user = null;
      warning('$runtimeType - Error authenticating user - $error');
    }
  }

  /// Authenticate using a web view.
  Future<void> authenticateWithMagicLink(String uri) async {
    try {
      await initialize();
      user = await CarpAuthService().authenticateWithMagicLink(uri);
      LocalSettings().isAnonymous = true;
      info('$runtimeType - ANONYMOUS User authenticated - user: $user');
    } catch (error) {
      user = null;
      warning('$runtimeType - ANONYMOUS Error authenticating user - $error');
    }
  }

  /// Refresh authentication token based on the refresh token.
  Future<CarpUser> refresh() async {
    user = await CarpAuthService().refresh();
    info('$runtimeType - User authenticated via refresh - user: $user');
    return user!;
  }

  /// Sign out from CAWS and erase all local authentication information.
  Future<void> signOut() async {
    if (CarpAuthService().authenticated) await CarpAuthService().logout();
    await LocalSettings().eraseAuthCredentials();
  }

  /// Has the user been authenticated?
  bool get isAuthenticated => CarpAuthService().authenticated;

  /// The user authenticated, if any.
  CarpUser? get user => LocalSettings().user;
  set user(CarpUser? user) => LocalSettings().user = user;

  /// The user name of the user, if authenticated.
  String? get username => user?.username;

  /// The Oauth token of the user, if authenticated.
  OAuthToken? get oauthToken => user?.token;

  /// The participant of this study, if an invitation has been accepted.
  Participant? get participant => LocalSettings().participant;

  /// The list of invitations for this user.
  /// Use [getInvitations] to get / refresh the list of invitations from CAWS.
  List<ActiveParticipationInvitation> invitations = [];

  /// Get the list of active invitations for this user from the [CarpParticipationService].
  Future<List<ActiveParticipationInvitation>> getInvitations() async {
    CarpParticipationService().configureFrom(CarpService());

    invitations =
        await CarpParticipationService().getActiveParticipationInvitations();

    // Filter the invitations to only include those that
    // have a smartphone as a device in [ActiveParticipationInvitation.assignedDevices] list
    // (i.e. the invitation is for a smartphone).
    // This is done to avoid showing invitations for other devices (e.g. [WebBrowser]).
    invitations.removeWhere((invitation) =>
        invitation.assignedDevices
            ?.any((device) => device.device is! Smartphone) ??
        false);

    return invitations;
  }

  /// Set the [study] used on this phone.
  set study(SmartphoneStudy study) {
    info('Setting (new) study in CAWS services - study: $study');
    CarpService().study = study;
    CarpParticipationService().study = study;
    CarpDeploymentService().study = study;
    CarpDataStreamService().study = study;
  }

  /// Upload the result of an informed consent flow. Returns the uploaded
  /// consent document.
  ///
  /// Looks for the first instance of a [RPConsentSignatureResult] in [consent]
  /// and uploads this.
  Future<InformedConsentInput?> uploadInformedConsent(
    RPTaskResult consent,
  ) async {
    if (user == null) {
      warning('$runtimeType - No user authenticated.');
      return null;
    }
    if (participant == null) {
      warning(
          '$runtimeType - No participant (no invitation has been accepted).');
      return null;
    }

    late RPConsentSignatureResult signedConsent;
    try {
      signedConsent = consent.results.values.firstWhere(
        (result) => result is RPConsentSignatureResult,
      ) as RPConsentSignatureResult;
    } catch (_) {
      warning(
          '$runtimeType - No signed informed consent found to be uploaded.');
      return null;
    }

    signedConsent.userId = username;
    final json = toJsonString(signedConsent.toJson());

    final uploadedConsent = InformedConsentInput(
      userId: user!.id,
      name: user!.username,
      consent: json,
      signatureImage: signedConsent.signature?.signatureImage ?? '',
    );

    try {
      await CarpParticipationService()
          .participation()
          .setInformedConsent(uploadedConsent);

      info('$runtimeType - Informed consent document uploaded successfully for '
          'deployment id: ${bloc.study?.studyDeploymentId}');
    } on Exception {
      warning(
          '$runtimeType - Informed consent upload failed for username: $username');
    }

    return uploadedConsent;
  }

  Future<InformedConsentInput?>? getInformedConsentByRole(
      String studyDeploymentId, String? role) async {
    return await CarpParticipationService()
        .participation(studyDeploymentId)
        .getInformedConsentByRole(role);
  }
}
