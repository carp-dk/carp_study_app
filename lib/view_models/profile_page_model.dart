part of carp_study_app;

class ProfilePageViewModel extends ViewModel {
  ProfilePageViewModel({AuthService? authService, StudyService? studyService, SystemInfoService? systemInfoService})
    : _authService = authService,
      _studyService = studyService,
      _systemInfoService = systemInfoService;

  final AuthService? _authService;
  final StudyService? _studyService;
  final SystemInfoService? _systemInfoService;

  AuthService get _auth => _authService ?? bloc.auth;
  StudyService get _study => _studyService ?? bloc.study;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;

  /// Did the user authenticate anonymously (magic link / QR)?
  bool get isAnonymous => _auth.isAnonymous;

  /// Is the phone connected to the internet?
  Future<bool> checkConnectivity() => _system.checkConnectivity();

  /// Sign out and leave the study.
  Future<void> signOutAndLeaveStudy() => bloc.signOutAndLeaveStudy();

  /// Leave the study, returning to the invitation list.
  Future<void> leaveStudy() => bloc.leaveStudy();

  String get userId => _auth.user?.id ?? _study.study?.participantId ?? '';
  String get username => _auth.username;
  String get firstName => _auth.user?.firstName ?? '';
  String get lastName => _auth.user?.lastName ?? '';
  String get fullName => '$firstName $lastName';
  String get email => _auth.user?.email ?? '';

  String get studyId => _study.deployment?.studyId ?? '';
  String get studyDeploymentId => _study.deployment?.studyDeploymentId ?? '';
  String get studyDeploymentTitle => _study.deployment?.studyDescription?.title ?? '';
  String get participantId => _study.study?.participantId ?? '';
  String get participantRole => _study.study?.participantRoleName ?? '';
  String get deviceRole => _study.deployment?.deviceRoleName ?? '';

  String get responsibleEmail => _study.deployment?.studyDescription?.responsible?.email ?? 'study@carp.dk';
  String get privacyPolicyUrl =>
      _study.deployment?.studyDescription?.privacyPolicyUrl ?? 'https://carp.dk/privacy-policy-app/';
  String get studyDescriptionUrl => _study.deployment?.studyDescription?.studyDescriptionUrl ?? '';
  String get deviceID => DeviceInfoService().deviceID ?? '';
  String get currentServer => _auth.serverUri.toString();
}
