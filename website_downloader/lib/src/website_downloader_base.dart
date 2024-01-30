import 'dart:convert';
import 'dart:io';

import 'package:common_extensions/uri_extension.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

///
class WebsiteDownloader {
  ///
  WebsiteDownloader({
    required this.websiteBaseUrl,
    required this.sourceBasePaths,
    required this.allowedSourcePaths,
    required this.contentContainerQuerySelector,
    required this.specialH1QuerySelector,
    required this.menuContainerQuerySelector,
    required this.downloadDirectory,
    this.removePrevDownloadDir = true,
  });

  ///
  final String websiteBaseUrl;

  ///
  final List<String> sourceBasePaths;

  ///
  final List<String> allowedSourcePaths;

  ///
  final String contentContainerQuerySelector;

  ///
  final String? specialH1QuerySelector;

  ///
  final String? menuContainerQuerySelector;

  ///
  final Directory downloadDirectory;

  ///
  final bool removePrevDownloadDir;

  ///
  Future<void> downloadFullWebsite() async {
    // Delete previous downloaded content for this website.
    if (downloadDirectory.existsSync()) await downloadDirectory.delete(recursive: true);

    final pathsToDownload = <String>[...sourceBasePaths];
    final downloadedPaths = <String>[];

    while (pathsToDownload.isNotEmpty) {
      final pathToDownload = pathsToDownload.removeLast();
      final discoveredPaths = await _downloadPage(pathToDownload);
      downloadedPaths.add(pathToDownload);
      for (final path in discoveredPaths) {
        if (!downloadedPaths.contains(path) &&
            !pathsToDownload.contains(path) &&
            _isAllowedSourcePath(path)) {
          pathsToDownload.add(path);
        }
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    await _savePagePaths(downloadedPaths);
  }

  Future<Set<String>> _downloadPage(String path) async {
    final discoveredPaths = <String>{};

    final uri = Uri.parse(p.join(websiteBaseUrl, path.substring(1)));

    final html = await _downloadHtml(uri);

    final document = parse(html);

    for (final anchor in document.body!.querySelectorAll('a')) {
      var path = (anchor.attributes['href'] ?? '#').trim();

      if (path.isEmpty || path == '#') continue;
      if (path.contains('#')) path = path.split('#').first;
      if (path.startsWith(websiteBaseUrl)) path = path.substring(websiteBaseUrl.length);
      if (path.endsWith('/')) path = path.substring(0, path.length - 1);
      if (path.endsWith('/index.html')) path = path.substring(0, path.length - 11);

      if (Uri.parse(path).hasFilename && lookupMimeType(path) != 'text/html') continue;

      discoveredPaths.add(path);
    }

    await _saveHtml(html, uri.path);

    return discoveredPaths;
  }

  Future<String> _downloadHtml(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode != 200) return '';

    return utf8.decode(response.bodyBytes);
  }

  Future<void> _saveHtml(String htmlContent, String pagePath) async {
    var path = pagePath;

    if (path.startsWith('/')) path = path.substring(1);
    if (path.endsWith('.htm')) path = path.substring(0, path.length - 4);
    if (path.endsWith('.php')) path = path.substring(0, path.length - 4);
    if (path.endsWith('.asp')) path = path.substring(0, path.length - 4);

    if (!path.endsWith('.html')) path += '.html';

    path = p.join(downloadDirectory.path, path);

    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(htmlContent);
  }

  Future<void> _savePagePaths(List<String> paths) async {
    final file = File('${downloadDirectory.path}/paths.txt');
    await file.parent.create(recursive: true);
    await file.writeAsString(paths.join('\n'));
  }

  ///
  bool _isAllowedSourcePath(String path) {
    return allowedSourcePaths.any((p) {
      final pLast = p[p.length - 1];
      return (pLast == '*' && path.startsWith(p.substring(0, p.length - 1))) || path == p;
    });
  }
}
