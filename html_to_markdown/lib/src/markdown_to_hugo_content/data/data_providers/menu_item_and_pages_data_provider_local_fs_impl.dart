import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:common_extensions_utils/utils.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/menu_item_and_pages_data_provider.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';
import 'package:path/path.dart' as p;

///
class MenuItemAndPagesDataProviderLocalFSImpl implements MenuItemAndPagesDataProvider {
  ///
  @override
  Future<void> initDataProvider() async {}

  ///
  @override
  Future<(List<MenuItem>, List<Page>)> menuItemsAndPages({
    required Directory mdConversionsDir,
    required String websiteBuildDirectoryName,
    required String websiteTitle,
    bool hasVersion = false,
  }) async {
    final menuJsonFile = File(
      p.join(mdConversionsDir.path, 'website-data-82361054', 'menu-0.json'),
    );

    final menuData = List<Map<dynamic, dynamic>>.from(
      jsonDecode(await menuJsonFile.readAsString()) as Iterable,
    );

    final pagesJsonFile = File(
      p.join(mdConversionsDir.path, 'website-data-82361054', 'pages.json'),
    );

    final pagesData = List<Map<String, dynamic>>.from(
      jsonDecode(await pagesJsonFile.readAsString()) as Iterable,
    );

    var generalPageId = 0;
    var generalMenuItemId = 1;

    final menuItems = <MenuItem>[
      MenuItem(
        id: generalMenuItemId,
        title: websiteTitle,
        weight: 1,
        path: '',
        slug: websiteBuildDirectoryName,
      ),
    ];

    if (hasVersion) {
      final version = p.basename(mdConversionsDir.path);
      generalMenuItemId++;
      menuItems.add(
        MenuItem(
          id: generalMenuItemId,
          title: '$websiteTitle $version',
          weight: 1,
          path: '',
          parentId: 1,
          slug: version,
        ),
      );
    }

    final pages = <Page>[];

    Future<void> inOrder(List<Map<dynamic, dynamic>> items, int parentMenuItemId) async {
      var weight = 0;
      for (final item in items) {
        weight++;

        if (item['items'] == null) {
          final pagePath = item['path'] as String;
          final pageData = pagesData.firstWhereOrNull((e) => e['path'] == pagePath);

          if (pageData != null) {
            generalPageId++;

            final pageTitle = pageData['title'];
            final pageDescription = pageData['description'];

            pages.add(
              Page(
                id: generalPageId,
                title: pageTitle as String,
                weight: weight,
                path: pagePath,
                menuItemId: parentMenuItemId,
                slug: p.basenameWithoutExtension(pagePath),
                linkTitle: item['title'] as String,
                description: pageDescription as String,
              ),
            );
          }
        } else {
          generalMenuItemId++;

          menuItems.add(
            MenuItem(
              id: generalMenuItemId,
              title: item['title'] as String,
              weight: weight,
              path: item['path'] as String,
              parentId: parentMenuItemId,
              slug: toSlug(item['title'] as String),
            ),
          );

          await inOrder(
            List<Map<dynamic, dynamic>>.from(item['items'] as Iterable),
            generalMenuItemId,
          );
        }
      }
    }

    await inOrder(menuData, generalMenuItemId);

    return (menuItems, pages);
  }
}
