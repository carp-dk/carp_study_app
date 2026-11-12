// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklyActivities _$WeeklyActivitiesFromJson(Map<String, dynamic> json) => WeeklyActivities()
  ..activities = (json['activities'] as Map<String, dynamic>).map(
    (k, e) => MapEntry($enumDecode(_$ActivityTypeEnumMap, k), Map<String, int>.from(e as Map)),
  );

Map<String, dynamic> _$WeeklyActivitiesToJson(WeeklyActivities instance) => <String, dynamic>{
  'activities': instance.activities.map((k, e) => MapEntry(_$ActivityTypeEnumMap[k]!, e)),
};

const _$ActivityTypeEnumMap = {
  ActivityType.IN_VEHICLE: 'IN_VEHICLE',
  ActivityType.ON_BICYCLE: 'ON_BICYCLE',
  ActivityType.RUNNING: 'RUNNING',
  ActivityType.STILL: 'STILL',
  ActivityType.WALKING: 'WALKING',
  ActivityType.UNKNOWN: 'UNKNOWN',
};
