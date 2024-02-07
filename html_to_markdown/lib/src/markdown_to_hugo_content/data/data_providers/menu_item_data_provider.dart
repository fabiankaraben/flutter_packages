import 'dart:io';

import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';

///
abstract class MenuItemDataProvider {
  ///
  Future<void> initDataProvider();

  ///
  Future<List<MenuItem>> menuItems({
    required Directory htmlDownloadsDir,
    required String websiteTitle,
  });
}
