import 'dart:io';

import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';

///
abstract class PageDataProvider {
  ///
  Future<void> initDataProvider();

  ///
  Future<List<Page>> pages({required Directory htmlDownloadsDir});
}
