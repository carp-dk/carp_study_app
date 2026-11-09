// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heart_rate_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HourlyHeartRate _$HourlyHeartRateFromJson(Map<String, dynamic> json) => HourlyHeartRate()
  ..hourlyHeartRate = (json['hourlyHeartRate'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, HeartRateMinMaxPrHour.fromJson(e as Map<String, dynamic>)),
  )
  ..dailyHeartRate = (json['dailyHeartRate'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, HeartRateMinMaxPrHour.fromJson(e as Map<String, dynamic>)),
  )
  ..maxHeartRate = (json['maxHeartRate'] as num?)?.toDouble()
  ..minHeartRate = (json['minHeartRate'] as num?)?.toDouble();

Map<String, dynamic> _$HourlyHeartRateToJson(HourlyHeartRate instance) => <String, dynamic>{
  'hourlyHeartRate': instance.hourlyHeartRate,
  'dailyHeartRate': instance.dailyHeartRate,
  'maxHeartRate': ?instance.maxHeartRate,
  'minHeartRate': ?instance.minHeartRate,
};

HeartRateMinMaxPrHour _$HeartRateMinMaxPrHourFromJson(Map<String, dynamic> json) =>
    HeartRateMinMaxPrHour((json['min'] as num?)?.toDouble(), (json['max'] as num?)?.toDouble());

Map<String, dynamic> _$HeartRateMinMaxPrHourToJson(HeartRateMinMaxPrHour instance) => <String, dynamic>{
  'min': ?instance.min,
  'max': ?instance.max,
};
