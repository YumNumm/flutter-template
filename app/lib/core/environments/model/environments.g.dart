// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Environments _$EnvironmentsFromJson(Map<String, dynamic> json) =>
    _Environments(
      flavor: $enumDecode(_$FlavorEnumMap, json['flavor']),
      appIdSuffix: json['appIdSuffix'] as String,
      appName: json['appName'] as String,
    );

Map<String, dynamic> _$EnvironmentsToJson(_Environments instance) =>
    <String, dynamic>{
      'flavor': _$FlavorEnumMap[instance.flavor]!,
      'appIdSuffix': instance.appIdSuffix,
      'appName': instance.appName,
    };

const _$FlavorEnumMap = {Flavor.dev: 'dev', Flavor.prod: 'prod'};
