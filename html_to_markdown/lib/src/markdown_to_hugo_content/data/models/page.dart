import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

///
@freezed
class Page with _$Page {
  ///
  const factory Page({
    required int id,
    required String title,
    required String path,
    required int weight,
    required String linkTitle,
    required String description,
    required String slug,
    int? menuItemId,
  }) = _Page;

  ///
  factory Page.fromJson(Map<String, Object?> json) => _$PageFromJson(json);
}
