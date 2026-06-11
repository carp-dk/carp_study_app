part of carp_study_app;

class ProfilePageViewModel extends ViewModel {
  String get userId => bloc.user?.id ?? bloc.study?.participantId ?? '';
  String get username => bloc.user?.username ?? '';
  String get firstName => bloc.user?.firstName ?? '';
  String get lastName => bloc.user?.lastName ?? '';
  String get fullName => '$firstName $lastName';
  String get email => bloc.user?.email ?? '';

  String get studyId => bloc.deployment?.studyId ?? '';
  String get studyDeploymentId => bloc.deployment?.studyDeploymentId ?? '';
  String get studyDeploymentTitle => bloc.deployment?.studyDescription?.title ?? '';
  String get participantId => bloc.study?.participantId ?? '';
  String get participantRole => bloc.study?.participantRoleName ?? '';
  String get deviceRole => bloc.deployment?.deviceRoleName ?? '';

  String get responsibleEmail => bloc.deployment?.studyDescription?.responsible?.email ?? 'study@carp.dk';
  String get privacyPolicyUrl =>
      bloc.deployment?.studyDescription?.privacyPolicyUrl ?? 'https://carp.dk/privacy-policy-app/';
  String get studyDescriptionUrl => bloc.deployment?.studyDescription?.studyDescriptionUrl ?? '';
  String get deviceID => DeviceInfoService().deviceID ?? '';
  String get currentServer => bloc.backend.uri.toString();

  ProfilePageViewModel();
}
