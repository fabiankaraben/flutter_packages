import 'dart:io';

import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/menu_item_and_pages_data_provider.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/menu_item_and_pages_data_provider_local_fs_impl.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';

///
class MenuItemsAndPagesRepository {
  MenuItemAndPagesDataProvider? _dataProvider;

  Future<MenuItemAndPagesDataProvider> _initRepository() async {
    if (_dataProvider == null) {
      _dataProvider = MenuItemAndPagesDataProviderLocalFSImpl();
      await _dataProvider!.initDataProvider();
    }
    return _dataProvider!;
  }

  ///
  Future<(List<MenuItem>, List<Page>)> menuItemsAndPages({
    required Directory mdConversionsDir,
    required String websiteBuildDirectoryName,
    required String websiteTitle,
    bool hasVersion = false,
  }) async {
    await _initRepository();
    return _dataProvider!.menuItemsAndPages(
      mdConversionsDir: mdConversionsDir,
      websiteBuildDirectoryName: websiteBuildDirectoryName,
      websiteTitle: websiteTitle,
      hasVersion: hasVersion,
    );
  }
}
