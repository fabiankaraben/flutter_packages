import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

///
@freezed
class MenuItem with _$MenuItem {
  ///
  const factory MenuItem({
    required int id,
    required String title,
    required int weight,
    required String? path,
    required String slug,
    int? parentId,
  }) = _MenuItem;

  ///
  factory MenuItem.fromJson(Map<String, Object?> json) => _$MenuItemFromJson(json);
}
