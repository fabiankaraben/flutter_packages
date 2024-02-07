import 'dart:io';

import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/page_data_provider.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/data_providers/page_data_provider_local_fs_impl.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';

///
class PagesRepository {
  PageDataProvider? _dataProvider;

  Future<PageDataProvider> _initRepository() async {
    if (_dataProvider == null) {
      _dataProvider = PageDataProviderLocalFSImpl();
      await _dataProvider!.initDataProvider();
    }
    return _dataProvider!;
  }

  ///
  Future<List<Page>> pages({required Directory htmlDownloadsDir}) async {
    await _initRepository();
    return _dataProvider!.pages(htmlDownloadsDir: htmlDownloadsDir);
  }
}
