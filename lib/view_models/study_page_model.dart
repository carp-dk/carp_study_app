part of carp_study_app;

/// The view model for the [StudyPage]. Mainly holds the list of messages like
/// news articles to be shown as part of the study.
class StudyPageViewModel extends ViewModel {
  StudyPageViewModel({StudyService? studyService, MessageService? messageService})
    : _studyService = studyService,
      _messageService = messageService;

  final StudyService? _studyService;
  final MessageService? _messageService;

  StudyService get _study => _studyService ?? bloc.study;
  MessageService get _messages => _messageService ?? bloc.messages;

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
