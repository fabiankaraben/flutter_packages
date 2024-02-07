import 'dart:io';

import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/menu_item_data_provider.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/menu_item_data_provider_local_fs_impl.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';

///
class MenuItemsRepository {
  MenuItemDataProvider? _dataProvider;

  Future<MenuItemDataProvider> _initRepository() async {
    if (_dataProvider == null) {
      _dataProvider = MenuItemDataProviderLocalFSImpl();
      await _dataProvider!.initDataProvider();
    }
    return _dataProvider!;
  }

  ///
  Future<List<MenuItem>> menuItems({
    required Directory htmlDownloadsDir,
    required String websiteTitle,
  }) async {
    await _initRepository();
    return _dataProvider!.menuItems(
      htmlDownloadsDir: htmlDownloadsDir,
      websiteTitle: websiteTitle,
    );
  }
}
