// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Participant _$ParticipantFromJson(Map<String, dynamic> json) => Participant(
  studyId: json['studyId'] as String?,
  studyDeploymentId: json['studyDeploymentId'] as String?,
  deviceRoleName: json['deviceRoleName'] as String?,
  participantId: json['participantId'] as String?,
  participantRoleName: json['participantRoleName'] as String?,
  hasInformedConsentBeenAccepted: json['hasInformedConsentBeenAccepted'] as bool? ?? false,
);

Map<String, dynamic> _$ParticipantToJson(Participant instance) => <String, dynamic>{
  'studyId': ?instance.studyId,
  'studyDeploymentId': ?instance.studyDeploymentId,
  'deviceRoleName': ?instance.deviceRoleName,
  'participantId': ?instance.participantId,
  'participantRoleName': ?instance.participantRoleName,
  'hasInformedConsentBeenAccepted': instance.hasInformedConsentBeenAccepted,
};
