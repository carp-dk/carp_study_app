part of carp_study_app;

/// A class representing a participant in a study.
///
/// This class is populated based on a study invitation and is saved across app
/// (re)start on the phone.
@JsonSerializable(includeIfNull: false)
class Participant {
  String? studyId;
  String? studyDeploymentId;
  String? deviceRoleName;
  String? participantId;
  String? participantRoleName;
  bool hasInformedConsentBeenAccepted = false;

  Participant({
    this.studyId,
    this.studyDeploymentId,
    this.deviceRoleName,
    this.participantId,
    this.participantRoleName,
    this.hasInformedConsentBeenAccepted = false,
  });

  Participant.fromParticipationInvitation(ActiveParticipationInvitation invitation)
    : this(
        studyId: invitation.studyId,
        studyDeploymentId: invitation.studyDeploymentId,
        deviceRoleName: invitation.assignedDevices?.first.device.roleName,
        participantId: invitation.participation.participantId,
        participantRoleName: invitation.participation.assignedRoles.roleNames?.first,
      );

  factory Participant.fromJson(Map<String, dynamic> json) => _$ParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
}
