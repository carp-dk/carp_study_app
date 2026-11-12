import 'dart:async';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:carp_study_app/core/backend/backend.dart';
import 'package:carp_study_app/core/settings/local_settings.dart';
import 'package:carp_study_app/core/settings/participant.dart';
import 'package:carp_study_app/core/util/app_config.dart';

/// Connection to the CAWS backend: the CAWS [app], authentication, study IDs,
/// and informed consent upload. Singleton via `CarpBackend()`.
class CarpBackend implements Backend {
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
  @override
  Uri get uri => Uri(scheme: 'https', host: uris[AppConfig.deploymentMode]);

  /// The URI of the CAWS authentication service.
  ///
  /// Of the form:
  ///    https://dev.carp.dk/auth/realms/Carp/
  Uri get authUri =>
      Uri(scheme: 'https', host: uris[AppConfig.deploymentMode], pathSegments: ['auth', 'realms', 'Carp']);

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
    discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
  );

  /// Initialize this backend. Must be called before used.
  @override
  Future<void> initialize() async {
    info('$runtimeType - initializing');
    await _configureAuth();
    CarpService().configure(app);
    _authEvents ??= CarpAuthService().authStateChanges.listen(_onAuthEvent);

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

    // CAWS services hold the active study as ambient state. If a study is
    // cached locally (returning user), re-seed the services here — otherwise
    // CarpResourceManager throws null-derefs on the first resource fetch.
    final cachedStudy = LocalSettings().study;
    if (cachedStudy != null) study = cachedStudy;

    info('$runtimeType initialized - app: $app');
  }

  bool _authConfigured = false;

  /// Configure CAWS auth, which fetches the OIDC discovery document.
  /// Offline this fails or hangs (no connect timeout in the SDK), so cap it and retry on next use.
  Future<void> _configureAuth() async {
    if (_authConfigured) return;
    try {
      await CarpAuthService().configure(authProperties).timeout(const Duration(seconds: 10));
      _authConfigured = true;
    } catch (error) {
      warning('$runtimeType - Could not reach CAWS auth - $error');
    }
  }

  /// Authenticate using a web view.
  @override
  Future<void> authenticate() async {
    await _configureAuth();
    try {
      user = await CarpAuthService().authenticate();
      LocalSettings().isAnonymous = false;
      info('$runtimeType - User authenticated - user: $user');
    } catch (error) {
      warning('$runtimeType - Error authenticating user - $error');
    }
  }

  /// The magic link belonging to a short sign-in [code], or null if CAWS
  /// does not know the code (or is unreachable).
  @override
  Future<String?> magicLinkForCode(String code) async {
    await _configureAuth();
    try {
      return await CarpAuthService().magicLinkForCode(code);
    } catch (error) {
      warning('$runtimeType - Could not resolve sign-in code - $error');
      return null;
    }
  }

  /// Authenticate anonymously using a magic link.
  @override
  Future<void> authenticateWithMagicLink(String uri) async {
    await _configureAuth();
    try {
      user = await CarpAuthService().authenticateWithMagicLink(uri);
      LocalSettings().isAnonymous = true;
      info('$runtimeType - ANONYMOUS User authenticated - user: $user');
    } catch (error) {
      warning('$runtimeType - ANONYMOUS Error authenticating user - $error');
    }
  }

  /// Refresh authentication token based on the refresh token.
  Future<CarpUser> refresh() async {
    await _configureAuth();
    user = await CarpAuthService().refresh();
    info('$runtimeType - User authenticated via refresh - user: $user');
    return user!;
  }

  StreamSubscription<AuthEvent>? _authEvents;

  /// Persist tokens the SDK refreshes on its own (e.g. on a 403 during upload).
  /// A failed refresh is surfaced as [sessionLost].
  void _onAuthEvent(AuthEvent event) {
    debug('$runtimeType - auth event: ${event.name}');
    switch (event) {
      case AuthEvent.authenticated:
      case AuthEvent.refreshed:
        if (CarpAuthService().authenticated) user = CarpAuthService().currentUser;
      case AuthEvent.failed:
      case AuthEvent.unauthenticated:
        break;
    }
  }

  @override
  Stream<void> get sessionLost => CarpAuthService().authStateChanges.where((event) => event == AuthEvent.failed);

  /// Sign out from CAWS and erase all local authentication information.
  @override
  Future<void> signOut() async {
    if (CarpAuthService().authenticated) await CarpAuthService().logout();
    await LocalSettings().eraseAuthCredentials();
  }

  /// Has the user been authenticated?
  @override
  bool get isAuthenticated => CarpAuthService().authenticated;

  /// The user authenticated, if any.
  @override
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
  @override
  Future<List<ActiveParticipationInvitation>> getInvitations() async {
    CarpParticipationService().configureFrom(CarpService());

    return invitations = await CarpParticipationService().getActiveParticipationInvitations();
  }

  /// Set the [study] used on this phone.
  @override
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
  @override
  Future<InformedConsentInput?> uploadInformedConsent(RPTaskResult consent) async {
    if (user == null) {
      warning('$runtimeType - No user authenticated.');
      return null;
    }
    if (participant == null) {
      warning('$runtimeType - No participant (no invitation has been accepted).');
      return null;
    }

    late RPConsentSignatureResult signedConsent;
    try {
      signedConsent =
          consent.results.values.firstWhere((result) => result is RPConsentSignatureResult) as RPConsentSignatureResult;
    } catch (_) {
      warning('$runtimeType - No signed informed consent found to be uploaded.');
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
      await CarpParticipationService().participation().setInformedConsent(uploadedConsent);

      info(
        '$runtimeType - Informed consent document uploaded successfully for '
        'deployment id: ${LocalSettings().study?.studyDeploymentId}',
      );
    } on Exception {
      warning('$runtimeType - Informed consent upload failed for username: $username');
    }

    return uploadedConsent;
  }

  @override
  Future<InformedConsentInput?> getInformedConsentByRole(String studyDeploymentId, String? role) async {
    return await CarpParticipationService().participation(studyDeploymentId).getInformedConsentByRole(role);
  }
}
