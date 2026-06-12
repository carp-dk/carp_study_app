part of carp_study_app;

/// The view model for the [StudyPage]. Mainly holds the list of messages like
/// news articles to be shown as part of the study.
class StudyPageViewModel extends ViewModel {
  StudyPageViewModel({StudyService? studyService, MessageService? messageService, SystemInfoService? systemInfoService})
    : _studyService = studyService,
      _messageService = messageService,
      _systemInfoService = systemInfoService;

  final StudyService? _studyService;
  final MessageService? _messageService;
  final SystemInfoService? _systemInfoService;
  bool _attachedToApp = false;
  bool _appUpdateAvailable = false;

  StudyService get _study => _studyService ?? bloc.study;
  MessageService get _messages => _messageService ?? bloc.messages;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;

  // Relay app-state changes (e.g. configuration completing) to the page, so
  // it only needs to listen to this view model. Attached lazily since the
  // global bloc is not available while this view model is constructed.
  @override
  void addListener(VoidCallback listener) {
    if (!_attachedToApp) {
      _attachedToApp = true;
      bloc.addListener(notifyListeners);
    }
    super.addListener(listener);
  }

  /// Is the app fully configured with the study?
  bool get isConfigured => bloc.isConfigured;

  /// Is the user signed in anonymously?
  bool get isAnonymousUser => LocalSettings().isAnonymous;

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

  /// Retry study configuration after a failure.
  Future<void> retryConfiguration() => bloc.tryConfigureStudy();

  String get title => _study.deployment?.studyDescription?.title ?? 'Unnamed';
  String get description => _study.deployment?.studyDescription?.description ?? '';
  String get purpose => _study.deployment?.studyDescription?.purpose ?? '';
  Image get image => Image.asset('assets/images/exercise.png');
  String? get userID => _study.study?.participantId;
  String get studyDeploymentId => _study.deployment?.studyDeploymentId ?? '';
  String get responsibleName => _study.deployment?.studyDescription?.responsible?.name ?? '';
  String get responsibleEmail => _study.deployment?.studyDescription?.responsible?.email ?? '';
  String get studyDescriptionUrl => _study.deployment?.studyDescription?.studyDescriptionUrl ?? '';
  String get privacyPolicyUrl =>
      _study.deployment?.studyDescription?.privacyPolicyUrl ?? 'https://carp.dk/privacy-policy-app/';

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
