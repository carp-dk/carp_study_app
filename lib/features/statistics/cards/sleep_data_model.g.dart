// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklySleep _$WeeklySleepFromJson(Map<String, dynamic> json) => WeeklySleep()
  ..nightlyMinutes = (json['nightlyMinutes'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as Map<String, dynamic>).map((k, e) => MapEntry(k, (e as num).toDouble()))),
  );

Map<String, dynamic> _$WeeklySleepToJson(WeeklySleep instance) => <String, dynamic>{
  'nightlyMinutes': instance.nightlyMinutes,
};
