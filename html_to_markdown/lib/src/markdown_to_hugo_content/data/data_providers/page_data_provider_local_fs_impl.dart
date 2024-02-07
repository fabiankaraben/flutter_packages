import 'dart:convert';
import 'dart:io';

import 'package:common_extensions/utils.dart';
import 'package:html/parser.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/page_data_provider.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';
import 'package:path/path.dart' as p;

///
class PageDataProviderLocalFSImpl implements PageDataProvider {
  ///
  @override
  Future<void> initDataProvider() async {}

  ///
  @override
  Future<List<Page>> pages({required Directory htmlDownloadsDir}) async {
    final jsonMenuFile = File(p.join(htmlDownloadsDir.path, 'menu-0.json'));

    final json = List<Map<dynamic, dynamic>>.from(
      jsonDecode(await jsonMenuFile.readAsString()) as Iterable,
    );

    final pages = <Page>[];
    var generalId = 0;
    var generalMenuItemId = 0;

    Future<void> inOrder(List<Map<dynamic, dynamic>> items, int menuItemId) async {
      var weight = 0;
      for (final item in items) {
        weight++;

        if (item['items'] == null) {
          generalId++;

          final pagePath = item['path'] as String;
          final pageFile = File(p.join(htmlDownloadsDir.path, pagePath.substring(1)));
          final html = await pageFile.readAsString();
          final document = parse(html);
          final pageTitle = document.head!.getElementsByTagName('title').first.text;
          final pageDesc =
              document.head?.querySelector('meta[name="description"]')?.attributes['content'] ?? '';

          pages.add(
            Page(
              id: generalId,
              title: pageTitle,
              weight: weight,
              path: pagePath,
              menuItemId: menuItemId,
              slug: toSlug(item['title'] as String),
              linkTitle: item['title'] as String,
              description: pageDesc,
            ),
          );
        } else {
          generalMenuItemId++;
          await inOrder(
            List<Map<dynamic, dynamic>>.from(item['items'] as Iterable),
            generalMenuItemId,
          );
        }
      }
    }

    await inOrder(json, 1);

    return pages;
  }
}
