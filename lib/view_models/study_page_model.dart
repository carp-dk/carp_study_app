part of carp_study_app;

/// The view model for the [StudyPage]. Mainly holds the list of messages like
/// news articles to be shown as part of the study.
class StudyPageViewModel extends ViewModel {
  String get title => bloc.deployment?.studyDescription?.title ?? 'Unnamed';
  String get description => bloc.deployment?.studyDescription?.description ?? '';
  String get purpose => bloc.deployment?.studyDescription?.purpose ?? '';
  Image get image => Image.asset('assets/images/exercise.png');
  String? get userID => bloc.study?.participantId;
  String get studyDeploymentId => bloc.deployment?.studyDeploymentId ?? '';
  String get responsibleName => bloc.deployment?.studyDescription?.responsible?.name ?? '';
  String get responsibleEmail => bloc.deployment?.studyDescription?.responsible?.email ?? '';
  String get studyDescriptionUrl => bloc.deployment?.studyDescription?.studyDescriptionUrl ?? '';
  String get privacyPolicyUrl =>
      bloc.deployment?.studyDescription?.privacyPolicyUrl ?? 'https://carp.dk/privacy-policy-app/';

  String get piTitle => bloc.deployment?.responsible?.title ?? '';
  String get piName => bloc.deployment?.responsible?.name ?? '';
  String get piAddress => bloc.deployment?.responsible?.address ?? '';
  String get piEmail => bloc.deployment?.responsible?.email ?? '';
  String get piAffiliation =>
      bloc.deployment?.responsible?.affiliation ?? 'Department of Health Technology, Technical University of Denmark';

  String get participantRole => bloc.study?.participantRoleName ?? '';
  String get deviceRole => bloc.deployment?.deviceRoleName ?? '';

  Future<StudyDeploymentStatus?> get studyDeploymentStatus => bloc.studyDeploymentStatus;

  /// The stream of messages (count)
  Stream<int> get messageStream => bloc.messageStream;

  /// The list of messages to be displayed.
  List<Message> get messages => bloc.messages.reversed.toList();

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
    timestamp: bloc.studyStartTimestamp ?? DateTime.now(),
    image: 'assets/images/kids.png',
  );
}
