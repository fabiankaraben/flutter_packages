import 'dart:io';

import 'package:html/dom.dart';

///
abstract class HtmlMenuToJsonPlugin {
  ///
  String convertMenuToJson(Element element, String pagePath);

  ///
  Future<void> saveJsonMenu(
    String stringJsonMenu,
    Directory htmlDownloadsDir,
    String websiteUrl,
    int menuIdx,
  );
}
