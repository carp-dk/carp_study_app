part of carp_study_app;

/// A local settings manager to store settings across app restart.
///
/// Settings include:
///
///  * [user] - the authentication information on a user
///  * [participant] - the information on a participant in the current [study]
///  * [study] - the study running on the phone
///
/// Works as a singleton - use `LocalSettings()` for accessing settings.
class LocalSettings {
  /// The package name of Google Health Connect.
  /// See https://developer.android.com/health-and-fitness/guides/health-connect/develop/get-started#get-client
  static const healthConnectPackageName = 'com.google.android.apps.healthdata';

  // Keys for storing in shared preferences
  static const String userKey = 'user';
  static const String participantKey = 'participant';
  static const String studyKey = 'study';

  CarpUser? _user;
  Participant? _participant;
  SmartphoneStudy? _study;

  static final LocalSettings _instance = LocalSettings._();
  factory LocalSettings() => _instance;
  LocalSettings._() : super();

  /// The user cached on this device, if any.
  ///
  /// The [user] is the user authenticated to the CAWS backend and stores
  /// authentication information and access tokens.
  CarpUser? get user {
    if (_user == null) {
      String? userString = Settings().preferences!.getString(userKey);

      _user = (userString != null) ? CarpUser.fromJson(jsonDecode(userString) as Map<String, dynamic>) : null;
    }
    return _user;
  }

  set user(CarpUser? user) {
    _user = user;
    if (user != null) {
      Settings().preferences!.setString(userKey, jsonEncode(user.toJson()));
    } else {
      Settings().preferences!.remove(userKey);
    }
  }

  /// The participant cached on this device, if any.
  ///
  /// The [participant] is the participant who is participating in a CARP study
  /// with a specific study deployment id, and who plays a certain role in this
  /// study by using a specific device.
  ///
  /// The [participant] is typically set based on an invitation set in the
  /// [StudyAppBLoC.setStudyInvitation] method.
  Participant? get participant {
    if (_participant == null) {
      String? userString = Settings().preferences!.getString(participantKey);
      _participant = (userString != null) ? Participant.fromJson(jsonDecode(userString) as Map<String, dynamic>) : null;
    }
    return _participant;
  }

  set participant(Participant? participant) {
    _participant = participant;
    if (participant != null) {
      Settings().preferences!.setString(participantKey, jsonEncode(participant.toJson()));
    } else {
      Settings().preferences!.remove(participantKey);
    }
  }

  /// The study for the currently running study deployment.
  /// The study is cached locally on the phone.
  /// Returns `null` if no study is deployed (yet).
  SmartphoneStudy? get study {
    if (_study != null) return _study;
    var jsonString = Settings().preferences?.getString(studyKey);
    return _study =
        (jsonString == null) ? null : _$SmartphoneStudyFromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  set study(SmartphoneStudy? study) {
    assert(
        study != null,
        'Cannot set the study to null in Settings. '
        "Use the 'eraseStudyDeployment()' method to erase study deployment information.");
    _study = study;
    Settings().preferences?.setString(
          studyKey,
          json.encode(_$SmartphoneStudyToJson(study!)),
        );
  }

  bool get hasSeenBluetoothConnectionInstructions =>
      Settings().preferences?.getBool('hasSeenBluetoothConnectionInstructions') ?? false;

  set hasSeenBluetoothConnectionInstructions(bool seen) {
    Settings().preferences?.setBool(
          'hasSeenBluetoothConnectionInstructions',
          seen,
        );
  }

  bool get isAnonymous => Settings().preferences!.getBool('isAnonymous') ?? false;
  set isAnonymous(bool value) => Settings().preferences!.setBool('isAnonymous', value);

  /// The study deployment id for the currently running deployment.
  String? get studyDeploymentId => _study?.studyDeploymentId;

  /// Erase all [study] information including the [participant] cached
  /// locally on this phone.
  Future<void> eraseStudyDeployment() async {
    _study = null;
    _participant = null;
    await Settings().preferences!.remove(participantKey);

    await Settings().preferences!.remove(studyKey);
    debug('$runtimeType - study deployment erased.');
  }

  /// Erase all authentication information on this user from the phone.
  Future<void> eraseAuthCredentials() async {
    _user = null;
    await Settings().preferences!.remove(userKey);
  }

  Future<String?> get deploymentBasePath async =>
      (studyDeploymentId == null) ? null : await Settings().getDeploymentBasePath(studyDeploymentId!);

  Future<String?> get cacheBasePath async =>
      (studyDeploymentId == null) ? null : await Settings().getCacheBasePath(studyDeploymentId!);
}

// Need to create our own JSON serializers here, since SmartphoneStudy is not made serializable
Map<String, dynamic> _$SmartphoneStudyToJson(SmartphoneStudy study) => <String, dynamic>{
      'studyId': study.studyId,
      'studyDeploymentId': study.studyDeploymentId,
      'deviceRoleName': study.deviceRoleName,
      'participantId': study.participantId,
      'participantRoleName': study.participantRoleName,
    };

SmartphoneStudy _$SmartphoneStudyFromJson(Map<String, dynamic> json) => SmartphoneStudy(
      studyId: json['studyId'] as String?,
      studyDeploymentId: json['studyDeploymentId'] as String,
      deviceRoleName: json['deviceRoleName'] as String,
      participantId: json['participantId'] as String?,
      participantRoleName: json['participantRoleName'] as String?,
    );
