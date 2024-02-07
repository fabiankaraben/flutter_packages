// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PageImpl _$$PageImplFromJson(Map<String, dynamic> json) => _$PageImpl(
      id: json['id'] as int,
      title: json['title'] as String,
      path: json['path'] as String,
      weight: json['weight'] as int,
      linkTitle: json['linkTitle'] as String,
      description: json['description'] as String,
      slug: json['slug'] as String,
      menuItemId: json['menuItemId'] as int?,
    );

Map<String, dynamic> _$$PageImplToJson(_$PageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'path': instance.path,
      'weight': instance.weight,
      'linkTitle': instance.linkTitle,
      'description': instance.description,
      'slug': instance.slug,
      'menuItemId': instance.menuItemId,
    };
