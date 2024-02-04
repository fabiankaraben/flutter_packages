import 'dart:convert';
import 'dart:io';

import 'package:common_extensions/utils.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json_typescript_impl.dart';
import 'package:docs_downloader/src/utils/path.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

///
class DocsDownloader {
  ///
  DocsDownloader({
    required this.downloadDirectory,
    this.removePrevDownloadDir = true,
  });

  ///
  final Directory downloadDirectory;

  ///
  final bool removePrevDownloadDir;

  /// Delete previous downloaded content for this website.
  Future<void> deletePreviousDownloadDirectory() async {
    if (downloadDirectory.existsSync()) await downloadDirectory.delete(recursive: true);
  }

  ///
  Future<List<String>> downloadGetSaveMenuPaths({
    required Uri menuPage,
    required String containerQuerySelector,
    required Directory downloadDirectory,
    required String websiteUrl,
    required int menuIndex,
  }) async {
    final html = await _downloadHtml(menuPage);

    final document = parse(html);

    if (document.body == null) return [];

    //
    // Html Menu to menu.json file.
    //

    // Get menu container element.
    final menuEl = document.body!.querySelector(containerQuerySelector);

    var stringJsonMenu = '';
    if (menuEl != null) {
      HtmlMenuToJsonPlugin? menuConverter;
      if (menuPage.path.contains('typescriptlang.org')) {
        menuConverter = HtmlMenuToJsonTypeScriptImpl();
      }
      if (menuConverter != null) {
        stringJsonMenu = menuConverter.convertMenuToJson(menuEl, menuPage.path);
        await menuConverter.saveJsonMenu(stringJsonMenu, downloadDirectory, websiteUrl, menuIndex);
      }
    }

    //
    // Get a list of paths to download the HTML content.
    //

    final menuData = List<Map<dynamic, dynamic>>.from(
      jsonDecode(stringJsonMenu) as Iterable,
    );

    final pathsToDownload = <String>[];

    void inOrder(List<Map<dynamic, dynamic>> items) {
      for (final item in items) {
        if (item['path'] != null && (item['path'] as String).trim().isNotEmpty) {
          var itemPath = item['path'] as String;

          if (itemPath.startsWith('/web/20')) {
            itemPath = 'https://web.archive.org$itemPath';
          } else if (itemPath.startsWith('/')) {
            itemPath = '$websiteUrl$itemPath';
          } else if (!itemPath.startsWith('/') && !itemPath.startsWith('http')) {
            itemPath = '$websiteUrl/$itemPath';
          }

          pathsToDownload.add(itemPath);
        }
        if (item['items'] != null) {
          inOrder(List<Map<dynamic, dynamic>>.from(item['items'] as Iterable));
        }
      }
    }

    inOrder(menuData);

    return pathsToDownload;
  }

  ///
  Future<void> downloadFullPage(String pageFullPath, String websiteUrl) async {
    final html = await _downloadHtml(Uri.parse(pageFullPath));

    final document = parse(html);

    for (final anchor in document.body!.querySelectorAll('a')) {
      anchor.attributes['href'] = getPathWithoutArchiveOrg(anchor.attributes['href'] ?? '');
    }

    await _saveHtml(
      document.outerHtml,
      leftCleanSourcePath(getPathWithoutArchiveOrg(pageFullPath), websiteUrl),
    );

    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Future<String> _downloadHtml(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode != 200) return '';

    return utf8.decode(response.bodyBytes);
  }

  Future<void> _saveHtml(String htmlContent, String pagePath) async {
    var path = pagePath;

    if (path.startsWith('/')) path = path.substring(1);
    if (path.contains('#')) path = path.split('#').first;
    if (path.contains('?')) path = path.split('?').first;
    if (path.endsWith('.htm')) path = path.substring(0, path.length - 4);
    if (path.endsWith('.php')) path = path.substring(0, path.length - 4);
    if (path.endsWith('.asp')) path = path.substring(0, path.length - 4);

    if (!path.endsWith('.html')) path += '.html';

    path = p.join(downloadDirectory.path, path);

    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(htmlContent);
  }
}
