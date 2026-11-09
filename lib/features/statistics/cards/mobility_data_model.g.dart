// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobility_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklyMobility _$WeeklyMobilityFromJson(Map<String, dynamic> json) => WeeklyMobility()
  ..dailyMobility = (json['dailyMobility'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, DailyMobility.fromJson(e as Map<String, dynamic>)),
  );

Map<String, dynamic> _$WeeklyMobilityToJson(WeeklyMobility instance) => <String, dynamic>{
  'dailyMobility': instance.dailyMobility,
};

DailyMobility _$DailyMobilityFromJson(Map<String, dynamic> json) => DailyMobility(
  DateTime.parse(json['date'] as String),
  (json['places'] as num).toInt(),
  (json['homeStay'] as num?)?.toInt(),
  (json['distance'] as num).toDouble(),
);

Map<String, dynamic> _$DailyMobilityToJson(DailyMobility instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'places': instance.places,
  'homeStay': ?instance.homeStay,
  'distance': instance.distance,
};
