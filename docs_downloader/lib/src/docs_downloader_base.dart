import 'dart:convert';
import 'dart:io';

import 'package:common_extensions_utils/directory_extension.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json_dart_impl_v1.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json_flutter_impl_v1.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json_nextjs_impl_v1.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json_react_impl_v1.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json_typescript_impl_v1.dart';
import 'package:docs_downloader/src/utils/path.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

///
class DocsDownloader {
  ///
  DocsDownloader({
    required this.intactHtmlDownloadsDir,
    required this.cleanHtmlDownloadsDir,
  });

  ///
  final Directory intactHtmlDownloadsDir;

  ///
  final Directory cleanHtmlDownloadsDir;

  final _allMenuPaths = <String>{};

  final _allImagePaths = <String>{};

  /// Delete previous downloaded content for this website.
  Future<void> deletePreviousCleanHtmlDownloadsDirectory() async {
    if (cleanHtmlDownloadsDir.existsSync()) await cleanHtmlDownloadsDir.delete(recursive: true);
  }

  /// Returns a list of page paths to download.
  Future<List<String>> downloadGetSaveMenuPaths({
    /// Absolute path of the page where the docs index menu is located.
    required String menuPagePath,

    /// CSS query selector to search the HTML element that contains the menu.
    required String containerQuerySelector,

    /// Clean website URL. Ex.: https://example.com
    required String websiteUrl,

    /// An index for this menu, usually 0. Useful for websites with multiple docs.
    required int menuIndex,

    ///
    int menuPluginVersion = 1,
  }) async {
    // Remove trailing slash if it exists
    if (websiteUrl.endsWith('/')) websiteUrl = websiteUrl.substring(0, websiteUrl.length - 1);

    final html = await _downloadHtml(Uri.parse(menuPagePath));

    final document = parse(html);

    if (document.body == null) return [];

    //
    // Html Menu to menu.json file.
    //

    // Get menu container element.
    final menuEl = document.body!.querySelector(containerQuerySelector);

    var menuData = <Map<dynamic, dynamic>>[];

    // Get the menu data.
    if (menuEl != null) {
      HtmlMenuToJsonPlugin? menuConverter;

      if (menuPagePath.contains('typescriptlang.org')) {
        menuConverter = HtmlMenuToJsonTypeScriptImplV1();
      } else if (menuPagePath.contains('reactjs.org')) {
        menuConverter = HtmlMenuToJsonReactImplV1();
      } else if (menuPagePath.contains('nextjs.org')) {
        menuConverter = HtmlMenuToJsonNextjsImplV1();
      } else if (menuPagePath.contains('dart.dev')) {
        menuConverter = HtmlMenuToJsonDartImplV1();
      } else if (menuPagePath.contains('flutter.dev')) {
        menuConverter = HtmlMenuToJsonFlutterImplV1();
      }

      if (menuConverter != null) {
        final stringJsonMenu = menuConverter.convertMenuToJson(menuEl).replaceAll('\n', '');
        menuData = List<Map<dynamic, dynamic>>.from(
          jsonDecode(stringJsonMenu) as Iterable,
        );
      }
    }

    // Save a menu-x.json file.
    if (menuData.isNotEmpty) {
      final menuDataCopy = List<Map<dynamic, dynamic>>.from(
        jsonDecode(jsonEncode(menuData)) as Iterable,
      );
      await _saveJsonMenu(
        menuPagePath: menuPagePath,
        menuData: menuDataCopy,
        websiteUrl: websiteUrl,
        menuIdx: menuIndex,
      );
    }

    //
    // Get a list of absolute source page paths to download its HTML content.
    //

    final pathsToDownload = <String>[];

    void inOrder(List<Map<dynamic, dynamic>> items) {
      for (final item in items) {
        var path = (item['path'] != null && (item['path'] as String).trim().isNotEmpty)
            ? (item['path'] as String).trim()
            : '';
        if (path.contains('#')) path = path.substring(0, path.indexOf('#'));
        if (path.contains('?')) path = path.substring(0, path.indexOf('?'));

        final isExternalUrl = (path.startsWith('https://') || path.startsWith('http://')) &&
            !path.startsWith(websiteUrl);

        if (path.isNotEmpty && !isExternalUrl) {
          pathsToDownload.add(
            _completeRemoteSourcePath(item['path'] as String, websiteUrl),
          );
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
  Future<void> _saveJsonMenu({
    required String menuPagePath,
    required List<Map<dynamic, dynamic>> menuData,
    required String websiteUrl,
    required int menuIdx,
  }) async {
    // Remove trailing slash if it exists
    if (websiteUrl.endsWith('/')) websiteUrl = websiteUrl.substring(0, websiteUrl.length - 1);

    void cleanInOrder(List<Map<dynamic, dynamic>> items) {
      for (final item in items) {
        if (item['path'] != null && (item['path'] as String).trim().isNotEmpty) {
          item['path'] = _getCleanWebsiteRootRelativePath(
            pathToConvert: item['path'] as String,
            websiteUrl: websiteUrl,
            parentPagePath: menuPagePath,
            removeQueryPart: true,
          );
          if (!(item['path'] as String).endsWith('.html')) item['path'] = '${item['path']}.html';

          // Register this path.
          _allMenuPaths.add(item['path'] as String);
        }
        if (item['items'] != null) {
          cleanInOrder(List<Map<dynamic, dynamic>>.from(item['items'] as Iterable));
        }
      }
    }

    // Clean all the paths.
    cleanInOrder(menuData);

    const encoder = JsonEncoder.withIndent('  ');

    final path = p.join(intactHtmlDownloadsDir.path, 'website-data-82361054', 'menu-$menuIdx.json');
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoder.convert(menuData));
  }

  ///
  Future<void> downloadFullPage({
    required String pageFullPath,
    required String websiteUrl,
    required String contentContainerQuerySelector,
  }) async {
    // Remove trailing slash if it exists
    if (websiteUrl.endsWith('/')) websiteUrl = websiteUrl.substring(0, websiteUrl.length - 1);

    final htmlFilePath = _getCleanWebsiteRootRelativePath(
      pathToConvert: pageFullPath,
      websiteUrl: websiteUrl,
      parentPagePath: '', // Irrelevant in this case.
      removeQueryPart: true,
      removeFragmentPart: true,
      addDotHtmlIfNotContains: true,
    );

    final htmlFile = File(p.join(intactHtmlDownloadsDir.path, htmlFilePath.substring(1)));

    if (htmlFile.existsSync()) return;

    final html = await _downloadHtml(Uri.parse(pageFullPath));
    final document = parse(html);

    // Download images.
    for (final img in document.body!.querySelectorAll('$contentContainerQuerySelector img')) {
      if (img.attributes['src'] == null) continue;

      final remoteSrc = _completeRemoteSourcePath(img.attributes['src']!, websiteUrl);

      _allImagePaths.add(remoteSrc);

      final remoteSourceUri = Uri.parse(remoteSrc);

      final imgPath = _getCleanImgPath(img.attributes['src']!, websiteUrl, pageFullPath);

      final file = File(
        p.join(
          intactHtmlDownloadsDir.path,
          'website-data-82361054',
          'assets',
          imgPath.substring(1),
        ),
      );

      if (!file.existsSync()) {
        late http.Response response;
        var attemptCount = 0;
        while (attemptCount < 50) {
          try {
            // print('Image: $remoteSourceUri');
            response = await http.get(remoteSourceUri);
            // print('Image response code: ${response.statusCode}');

            if (response.statusCode == 200) {
              await file.parent.create(recursive: true);
              await file.writeAsBytes(response.bodyBytes);
            } else {
              // Try download image without archive.org URL part.
              // print('Image without archive.org');
              response = await http.get(
                Uri.parse(
                  getPathWithoutArchiveOrg(remoteSourceUri.toString()),
                ),
              );
              if (response.statusCode == 200) {
                await file.parent.create(recursive: true);
                await file.writeAsBytes(response.bodyBytes);
              }
            }
            break;
          } on http.ClientException {
            // print('Image ClientException');
            await Future<void>.delayed(const Duration(minutes: 1));
          } catch (e) {
            rethrow;
          }
          attemptCount++;
        }
      }
    }

    await htmlFile.parent.create(recursive: true);
    await htmlFile.writeAsString(html);
  }

  ///
  Future<void> cleanAllPages({
    required List<String> menuPagePaths,
    required String websiteUrl,
    required String contentContainerQuerySelector,
  }) async {
    // Clean pages (link paths, image paths, ...).
    for (final menuPagePath in menuPagePaths) {
      await _cleanFullPage(
        pageFullPath: menuPagePath,
        websiteUrl: websiteUrl,
        contentContainerQuerySelector: contentContainerQuerySelector,
      );
    }

    // Copy website data (assets and JSON files).
    final websiteDataDir = Directory(p.join(intactHtmlDownloadsDir.path, 'website-data-82361054'));
    if (websiteDataDir.existsSync()) {
      await websiteDataDir.copyContent(
        Directory(p.join(cleanHtmlDownloadsDir.path, 'website-data-82361054')),
      );
    }

    // Save images.txt file.
    final imagesFile = File(
      p.join(intactHtmlDownloadsDir.path, 'website-data-82361054', 'images.txt'),
    );
    await imagesFile.writeAsString(_allImagePaths.join('\n'));
  }

  ///
  Future<void> _cleanFullPage({
    required String pageFullPath,
    required String websiteUrl,
    required String contentContainerQuerySelector,
  }) async {
    // Remove trailing slash if it exists
    if (websiteUrl.endsWith('/')) websiteUrl = websiteUrl.substring(0, websiteUrl.length - 1);

    final htmlFilePath = _getCleanWebsiteRootRelativePath(
      pathToConvert: pageFullPath,
      websiteUrl: websiteUrl,
      parentPagePath: '', // Irrelevant in this case.
      removeQueryPart: true,
      removeFragmentPart: true,
      addDotHtmlIfNotContains: true,
    );

    final intactHtmlFile = File(p.join(intactHtmlDownloadsDir.path, htmlFilePath.substring(1)));
    final html = await intactHtmlFile.readAsString();
    final document = parse(html);

    // Clean anchors href attribute. Always website root relative paths starting with '/'.
    for (final anchor in document.body!.querySelectorAll('$contentContainerQuerySelector a')) {
      if (!anchor.attributes.containsKey('href')) continue;

      final href = anchor.attributes['href']!;
      if (!href.startsWith(websiteUrl) && href.contains('http') && !href.contains(websiteUrl)) {
        // Externar URL in href.
        anchor.attributes['href'] = getPathWithoutArchiveOrg(anchor.attributes['href']!);
      } else {
        // Internal URL in href.
        anchor.attributes['href'] = _getCleanWebsiteRootRelativePath(
          pathToConvert: anchor.attributes['href']!,
          websiteUrl: websiteUrl,
          parentPagePath: pageFullPath,
          removeQueryPart: true,
          addDotHtmlIfNotContains: true,
        );
      }
    }

    // Clean images.
    for (final img in document.body!.querySelectorAll('$contentContainerQuerySelector img')) {
      if (img.attributes['src'] == null) continue;

      final imgPath = _getCleanImgPath(img.attributes['src']!, websiteUrl, pageFullPath);

      //
      img.attributes['src'] = '/assets$imgPath';
    }

    // Save HTML file.
    final cleanHtmlFile = File(p.join(cleanHtmlDownloadsDir.path, htmlFilePath.substring(1)));
    await cleanHtmlFile.parent.create(recursive: true);
    await cleanHtmlFile.writeAsString(document.outerHtml);
  }

  String _getCleanImgPath(String imgSrc, String websiteUrl, String pageFullPath) {
    late String imgPath;

    // For Next.js images.
    if (imgSrc.contains('/_next/image?')) {
      final url = Uri.parse(
        imgSrc.substring(imgSrc.indexOf('/_next/image?')),
      ).queryParameters['url'];
      // print('URL: $url');
      imgPath = url ?? imgSrc;
    } else {
      imgPath = _getCleanWebsiteRootRelativePath(
        pathToConvert: imgSrc,
        websiteUrl: websiteUrl,
        parentPagePath: pageFullPath,
        removeQueryPart: true,
        removeFragmentPart: true,
      );

      // Check for external paths.
      // If imgPath still contains '/http' then this is an external image path.
      // Ex.: /docs/handbook/release-notes/https:/raw.githubusercontent.com/wiki/Mi..../image.png
      if (imgPath.contains('/http')) {
        imgPath = '/external/${imgPath.substring(imgPath.indexOf(':/') + 2)}';
      }
    }

    return imgPath;
  }

  Future<String> _downloadHtml(Uri uri) async {
    late http.Response response;
    var attemptCount = 0;

    // Retry waiting one minute on ClientException case, up to 50 times.
    while (attemptCount < 50) {
      try {
        response = await http.get(uri);
        // print('${response.statusCode} ${uri.path}');

        return response.statusCode == 200 ? utf8.decode(response.bodyBytes) : '';
      } on http.ClientException {
        // print('ClientException: ${uri.path}');
        await Future<void>.delayed(const Duration(minutes: 1));
      } catch (e) {
        rethrow;
      }
      attemptCount++;
    }

    return '';
  }

  String _completeRemoteSourcePath(String remotePath, String websiteUrl) {
    var path = remotePath;
    if (path.startsWith('/web/20')) {
      path = 'https://web.archive.org$path';
    } else if (path.startsWith('/')) {
      path = '$websiteUrl$path';
    } else if (!path.startsWith('/') && !path.startsWith('http')) {
      path = '$websiteUrl/$path';
    }
    return path;
  }

  String _getCleanWebsiteRootRelativePath({
    /// Path of the link or resource on the page. Path to be cleaned.
    required String pathToConvert,

    /// Clean website URL. Ex.: https://example.com
    required String websiteUrl,

    /// Path of the page where [pathToConvert] was found.
    required String parentPagePath,

    /// Remove query part. Ex.: ?par1=val1&par2=val2
    bool removeQueryPart = false,

    /// Remove fragment part. Ex.: #the-title
    bool removeFragmentPart = false,

    /// Add .html at the end of the path if it not contains.
    bool addDotHtmlIfNotContains = false,
  }) {
    // Remove trailing slash if it exists
    if (websiteUrl.endsWith('/')) websiteUrl = websiteUrl.substring(0, websiteUrl.length - 1);

    // Remove web.archive.org part.
    var path = getPathWithoutArchiveOrg(pathToConvert);

    // Remove the authority part. Ex.: https://example.com/foo -> /foo.
    if (path.startsWith(websiteUrl)) path = path.substring(websiteUrl.length);

    // Temporally remove the fragment part.
    var fragmentPart = '';
    if (path.contains('#')) {
      final charIdx = path.indexOf('#');
      fragmentPart = path.substring(charIdx);
      path = path.substring(0, charIdx);
    }

    // Temporally remove the query part.
    var queryPart = '';
    if (path.contains('?')) {
      final charIdx = path.indexOf('?');
      queryPart = path.substring(charIdx);
      path = path.substring(0, charIdx);
    }

    // Convert local relative path to root relative path. Ex.: 'something' to '/foo/bar/something'.
    if (!path.startsWith('/')) {
      // Recursively get a clean parent page path.
      parentPagePath = _getCleanWebsiteRootRelativePath(
        pathToConvert: parentPagePath,
        websiteUrl: websiteUrl,
        parentPagePath: '', // Irrelevant in this case.
        removeQueryPart: true,
        removeFragmentPart: true,
      );

      if (path.trim().isEmpty) {
        // Ex.: for hrefs like '#something'
        path = parentPagePath;
      } else {
        path = p.join(p.dirname(parentPagePath), path);
      }
    }

    if (addDotHtmlIfNotContains && !path.endsWith('.html')) {
      // Check to avoid cases like /tsconfig/.html or /play/.html.
      var auxPath = path;
      if (auxPath.endsWith('/')) auxPath = auxPath.substring(0, auxPath.length - 1);
      final extension = p.extension(auxPath);
      if (extension.isNotEmpty) auxPath = auxPath.substring(0, auxPath.length - extension.length);
      auxPath = '$auxPath.html';

      // And only applies to the paths found in the menu.
      if (_allMenuPaths.contains(auxPath)) {
        path = auxPath;
      }
    }

    // Normalize before restore the query and fragment parts.
    path = p.normalize(path);

    // Restore query part.
    if (!removeQueryPart) path = '$path$queryPart';
    // Restore fragment part.
    if (!removeFragmentPart) path = '$path$fragmentPart';

    return path;
  }
}
