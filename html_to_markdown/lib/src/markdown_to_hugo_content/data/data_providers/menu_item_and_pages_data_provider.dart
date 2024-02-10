import 'dart:io';

import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';

///
abstract class MenuItemAndPagesDataProvider {
  ///
  Future<void> initDataProvider();

  ///
  Future<(List<MenuItem>, List<Page>)> menuItemsAndPages({
    required Directory mdConversionsDir,
    required String websiteBuildDirectoryName,
    required String websiteTitle,
    bool hasVersion = false,
  });
}
