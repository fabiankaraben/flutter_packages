import 'dart:io';

import 'package:html/dom.dart';

///
abstract class HtmlMenuToJsonPlugin {
  ///
  String convertMenuToJson(Element element, String pagePath);

  ///
  Future<void> saveJsonMenu(
    String stringJsonMenu,
    Directory downloadDirectory,
    String websiteUrl,
    int menuIdx,
  );
}
