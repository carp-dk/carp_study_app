part of carp_study_app;

/// View model for [StudyPage] and [StudyAboutPage] - study description,
/// deployment status, and published messages, incl. pull-to-refresh.
class StudyPageViewModel extends ViewModel {
  StudyPageViewModel({
    StudyService? studyService,
    MessageService? messageService,
    SystemInfoService? systemInfoService,
    AuthService? authService,
    ConsentService? consentService,
  }) : _studyService = studyService,
       _messageService = messageService,
       _systemInfoService = systemInfoService,
       _authService = authService,
       _consentService = consentService;

  final StudyService? _studyService;
  final MessageService? _messageService;
  final SystemInfoService? _systemInfoService;
  final AuthService? _authService;
  final ConsentService? _consentService;
  bool _appUpdateAvailable = false;

  StudyService get _study => _studyService ?? bloc.study;
  MessageService get _messages => _messageService ?? bloc.messages;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;
  AuthService get _auth => _authService ?? bloc.auth;
  ConsentService get _consent => _consentService ?? bloc.consent;

  /// Is the user signed in anonymously?
  bool get isAnonymousUser => _auth.isAnonymous;

  /// Is a newer version of this app available? Checked once on [init].
  bool get appUpdateAvailable => _appUpdateAvailable;

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    unawaited(_checkAppUpdate());
  }

  Future<void> _checkAppUpdate() async {
    try {
      _appUpdateAvailable = await _system.getAppHasUpdate() ?? false;
    } catch (error) {
      _appUpdateAvailable = false;
    }
    notifyListeners();
  }

  /// Re-fetch messages, re-try deployment if needed, (re)start sensing, and
  /// refresh the deployment status. Used on pull-to-refresh.
  Future<void> refresh() async {
    await _messages.refresh();
    await _study.tryDeployment();
    await _study.start();
    await _study.refreshDeploymentStatus();
  }

  String get title => _study.deployment?.studyDescription?.title ?? 'Unnamed';
  String get description => _study.deployment?.studyDescription?.description ?? '';
  String get purpose => _study.deployment?.studyDescription?.purpose ?? '';
  Image get image => Image.asset('assets/images/exercise.png');
  String? get userID => _study.study?.participantId;
  String get studyDeploymentId => _study.deployment?.studyDeploymentId ?? '';
  String get responsibleName => _study.deployment?.studyDescription?.responsible?.name ?? '';
  String get responsibleEmail => _study.deployment?.studyDescription?.responsible?.email ?? '';
  String get studyDescriptionUrl => _study.deployment?.studyDescription?.studyDescriptionUrl ?? '';

  /// The study's own privacy policy, falling back to the general CARP one.
  String get privacyPolicyUrl => _study.deployment?.studyDescription?.privacyPolicyUrl ?? CarpBackend.carpPrivacyUrl;
  String get username => _auth.username;

  /// The signed informed consent, as the bytes to save to a file.
  ///
  /// Null when no signed consent exists (e.g. local deployments).
  Future<Uint8List?> informedConsentBytes() => _consent.signedConsentBytes(_study.study);

  String get piTitle => _study.deployment?.responsible?.title ?? '';
  String get piName => _study.deployment?.responsible?.name ?? '';
  String get piAddress => _study.deployment?.responsible?.address ?? '';
  String get piEmail => _study.deployment?.responsible?.email ?? '';
  String get piAffiliation =>
      _study.deployment?.responsible?.affiliation ?? 'Department of Health Technology, Technical University of Denmark';

  String get participantRole => _study.study?.participantRoleName ?? '';
  String get deviceRole => _study.deployment?.deviceRoleName ?? '';

  Future<StudyDeploymentStatus?> get studyDeploymentStatus => _study.refreshDeploymentStatus();

  /// The stream of messages (count)
  Stream<int> get messageStream => _messages.stream;

  /// The list of messages to be displayed.
  List<Message> get messages => _messages.messages.reversed.toList();

  /// The message with [id], or a placeholder if it is not found.
  Message messageById(String id) =>
      _messages.byId(id) ??
      Message(
        id: '0',
        title: 'Unknown message',
        subTitle: 'Unknown message',
        type: MessageType.announcement,
        timestamp: DateTime.now(),
        image: './assets/images/kids.png',
      );

  /// Get the image based on [imagePath]. Can be both an asset and a network
  /// image. See [Message.imagePath].
  ///
  /// If [imagePath] is null, a random image is returned.
  Image getMessageImage(String? imagePath) {
    Image image;
    imagePath ??= 'assets/images/messages/img_${Random(10).nextInt(5) + 1}.png';

    if (imagePath.startsWith('http')) {
      image = Image.network(imagePath, fit: BoxFit.fitHeight);
    } else {
      image = Image.asset(imagePath, fit: BoxFit.fitHeight);
    }
    return image;
  }

  static const dummyID = '00000000-0000-0000-0000-000000000000';
  Message get studyDescriptionMessage => Message(
    id: dummyID,
    title: title,
    message: description,
    type: MessageType.announcement,
    timestamp: _study.studyStartTimestamp ?? DateTime.now(),
    image: 'assets/images/kids.png',
  );
}
