// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Participant _$ParticipantFromJson(Map<String, dynamic> json) => Participant(
  studyId: json['studyId'] as String?,
  studyDeploymentId: json['studyDeploymentId'] as String?,
  deviceRoleName: json['deviceRoleName'] as String?,
  participantId: json['participantId'] as String?,
  participantRoleName: json['participantRoleName'] as String?,
  hasInformedConsentBeenAccepted:
      json['hasInformedConsentBeenAccepted'] as bool? ?? false,
);

Map<String, dynamic> _$ParticipantToJson(Participant instance) =>
    <String, dynamic>{
      'studyId': ?instance.studyId,
      'studyDeploymentId': ?instance.studyDeploymentId,
      'deviceRoleName': ?instance.deviceRoleName,
      'participantId': ?instance.participantId,
      'participantRoleName': ?instance.participantRoleName,
      'hasInformedConsentBeenAccepted': instance.hasInformedConsentBeenAccepted,
    };

WeeklyActivities _$WeeklyActivitiesFromJson(Map<String, dynamic> json) =>
    WeeklyActivities()
      ..activities = (json['activities'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          $enumDecode(_$ActivityTypeEnumMap, k),
          (e as Map<String, dynamic>).map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ),
        ),
      );

Map<String, dynamic> _$WeeklyActivitiesToJson(WeeklyActivities instance) =>
    <String, dynamic>{
      'activities': instance.activities.map(
        (k, e) => MapEntry(
          _$ActivityTypeEnumMap[k]!,
          e.map((k, e) => MapEntry(k.toString(), e)),
        ),
      ),
    };

const _$ActivityTypeEnumMap = {
  ActivityType.IN_VEHICLE: 'IN_VEHICLE',
  ActivityType.ON_BICYCLE: 'ON_BICYCLE',
  ActivityType.RUNNING: 'RUNNING',
  ActivityType.STILL: 'STILL',
  ActivityType.WALKING: 'WALKING',
  ActivityType.UNKNOWN: 'UNKNOWN',
};

WeeklyMobility _$WeeklyMobilityFromJson(Map<String, dynamic> json) =>
    WeeklyMobility()
      ..weekMobility = (json['weekMobility'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          DailyMobility.fromJson(e as Map<String, dynamic>),
        ),
      );

Map<String, dynamic> _$WeeklyMobilityToJson(WeeklyMobility instance) =>
    <String, dynamic>{
      'weekMobility': instance.weekMobility.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
    };

DailyMobility _$DailyMobilityFromJson(Map<String, dynamic> json) =>
    DailyMobility(
      (json['weekday'] as num).toInt(),
      (json['places'] as num).toInt(),
      (json['homeStay'] as num).toInt(),
      (json['distance'] as num).toDouble(),
    );

Map<String, dynamic> _$DailyMobilityToJson(DailyMobility instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'places': instance.places,
      'homeStay': instance.homeStay,
      'distance': instance.distance,
    };

WeeklySteps _$WeeklyStepsFromJson(Map<String, dynamic> json) => WeeklySteps()
  ..weeklySteps = (json['weeklySteps'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
  );

Map<String, dynamic> _$WeeklyStepsToJson(
  WeeklySteps instance,
) => <String, dynamic>{
  'weeklySteps': instance.weeklySteps.map((k, e) => MapEntry(k.toString(), e)),
};

HourlyHeartRate _$HourlyHeartRateFromJson(Map<String, dynamic> json) =>
    HourlyHeartRate()
      ..hourlyHeartRate = (json['hourlyHeartRate'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          HeartRateMinMaxPrHour.fromJson(e as Map<String, dynamic>),
        ),
      )
      ..dailyHeartRate = (json['dailyHeartRate'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          HeartRateMinMaxPrHour.fromJson(e as Map<String, dynamic>),
        ),
      )
      ..lastUpdated = DateTime.parse(json['lastUpdated'] as String)
      ..maxHeartRate = (json['maxHeartRate'] as num?)?.toDouble()
      ..minHeartRate = (json['minHeartRate'] as num?)?.toDouble();

Map<String, dynamic> _$HourlyHeartRateToJson(HourlyHeartRate instance) =>
    <String, dynamic>{
      'hourlyHeartRate': instance.hourlyHeartRate.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'dailyHeartRate': instance.dailyHeartRate.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'maxHeartRate': ?instance.maxHeartRate,
      'minHeartRate': ?instance.minHeartRate,
    };

HeartRateMinMaxPrHour _$HeartRateMinMaxPrHourFromJson(
  Map<String, dynamic> json,
) => HeartRateMinMaxPrHour(
  (json['min'] as num?)?.toDouble(),
  (json['max'] as num?)?.toDouble(),
);

Map<String, dynamic> _$HeartRateMinMaxPrHourToJson(
  HeartRateMinMaxPrHour instance,
) => <String, dynamic>{'min': ?instance.min, 'max': ?instance.max};
