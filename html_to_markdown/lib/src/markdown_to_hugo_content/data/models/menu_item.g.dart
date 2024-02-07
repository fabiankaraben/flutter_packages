// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MenuItemImpl _$$MenuItemImplFromJson(Map<String, dynamic> json) =>
    _$MenuItemImpl(
      id: json['id'] as int,
      title: json['title'] as String,
      weight: json['weight'] as int,
      path: json['path'] as String?,
      slug: json['slug'] as String,
      parentId: json['parentId'] as int?,
    );

Map<String, dynamic> _$$MenuItemImplToJson(_$MenuItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'weight': instance.weight,
      'path': instance.path,
      'slug': instance.slug,
      'parentId': instance.parentId,
    };
