import 'dart:convert';
import 'dart:io';

import 'package:common_extensions/utils.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/menu_item_data_provider.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';
import 'package:path/path.dart' as p;

///
class MenuItemDataProviderLocalFSImpl implements MenuItemDataProvider {
  ///
  @override
  Future<void> initDataProvider() async {}

  ///
  @override
  Future<List<MenuItem>> menuItems({
    required Directory htmlDownloadsDir,
    required String websiteTitle,
  }) async {
    final jsonMenuFile = File(p.join(htmlDownloadsDir.path, 'menu-0.json'));

    final json = List<Map<dynamic, dynamic>>.from(
      jsonDecode(await jsonMenuFile.readAsString()) as Iterable,
    );

    var generalId = 1;
    final menuItems = <MenuItem>[
      MenuItem(
        id: generalId,
        title: websiteTitle,
        weight: 1,
        path: '',
        slug: '',
      ),
    ];

    void inOrder(List<Map<dynamic, dynamic>> items, int parentId) {
      var weight = 0;
      for (final item in items) {
        weight++;

        if (item['items'] != null) {
          generalId++;

          menuItems.add(
            MenuItem(
              id: generalId,
              title: item['title'] as String,
              weight: weight,
              path: item['path'] as String,
              parentId: parentId,
              slug: toSlug(item['title'] as String),
            ),
          );

          inOrder(List<Map<dynamic, dynamic>>.from(item['items'] as Iterable), generalId);
        }
      }
    }

    inOrder(json, 1);

    return menuItems;
  }
}
