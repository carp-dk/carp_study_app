part of carp_study_app;

/// The [Backend] for local mode - same flow as CAWS, but nothing leaves the phone.
///
/// Any sign-in succeeds, the one invitation is the protocol in
/// `assets/carp/resources/protocol.json`, and everything lives in memory,
/// so a restart starts over with the current files.
class LocalBackend implements Backend {
  static final LocalBackend _instance = LocalBackend._();
  factory LocalBackend() => _instance;
  LocalBackend._();

  CarpUser? _user;
  ActiveParticipationInvitation? _invitation;
  final Map<String, InformedConsentInput> _consents = {};

  @override
  Uri get uri => Uri.parse('local://${LocalResourceManager.basePath}');

  @override
  // Sensing registers the device types (location, Polar, ...) the protocol needs to deserialize.
  Future<void> initialize() async => Sensing();

  @override
  bool get isAuthenticated => _user != null;

  @override
  CarpUser? get user => _user;

  @override
  Future<void> authenticate() async => _signIn(anonymous: false);

  @override
  Future<String?> magicLinkForCode(String code) async => 'local://code/$code';

  @override
  Future<void> authenticateWithMagicLink(String uri) async => _signIn(anonymous: true);

  void _signIn({required bool anonymous}) {
    _user = CarpUser(username: 'local', id: 'local-user');
    LocalSettings().isAnonymous = anonymous;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _invitation = null;
    _consents.clear();
  }

  /// The invitation to the local study - deployed on the phone on first request.
  @override
  Future<List<ActiveParticipationInvitation>> getInvitations() async => [_invitation ??= await _invite()];

  Future<ActiveParticipationInvitation> _invite() async {
    final protocol = await LocalResourceManager().getStudyProtocol('');
    if (protocol == null) {
      throw StateError("No valid study protocol in '${LocalResourceManager.basePath}/resources/protocol.json'.");
    }

    // CAMS registers `thisPhone` on deployment - it must be the protocol's phone,
    // whatever role name the protocol gives it (e.g. 'Primary Phone').
    final device = protocol.primaryDevices.whereType<Smartphone>().firstOrNull;
    if (device == null) throw StateError('The local protocol has no Smartphone primary device.');
    SmartphoneDeploymentService().thisPhone = device;
    final status = await SmartphoneDeploymentService().createStudyDeployment(protocol);
    final role = protocol.participantRoles?.firstOrNull?.role;

    // CAWS sends the invitation text as plain text, but the protocol holds translation
    // keys, and study translations only load once a study is selected - resolve them here.
    final translations = await LocalResourceManager()
        .getLocalizations(AppConfig.localization?.locale ?? const Locale('en'))
        .catchError((_) => <String, String>{}); // no lang files - keep the text as is
    final description = translations[protocol.description] ?? protocol.description;

    return ActiveParticipationInvitation(
      Participation(status.studyDeploymentId, 'local-participant', AssignedTo(roleNames: role == null ? null : {role})),
      StudyInvitation(protocol.name, description, {'studyId': protocol.id}),
    )..assignedDevices = [AssignedPrimaryDevice(device: device)];
  }

  @override
  set study(SmartphoneStudy study) {}

  @override
  Future<InformedConsentInput?> uploadInformedConsent(RPTaskResult consent) async {
    final signature = consent.results.values.whereType<RPConsentSignatureResult>().firstOrNull;
    final study = LocalSettings().study;
    if (signature == null || study == null) return null;

    return _consents[study.studyDeploymentId] = InformedConsentInput(
      userId: _user?.id ?? '',
      name: _user?.username ?? '',
      consent: toJsonString(signature.toJson()),
      signatureImage: signature.signature?.signatureImage ?? '',
    );
  }

  @override
  Future<InformedConsentInput?> getInformedConsentByRole(String studyDeploymentId, String? role) async =>
      _consents[studyDeploymentId];
}
