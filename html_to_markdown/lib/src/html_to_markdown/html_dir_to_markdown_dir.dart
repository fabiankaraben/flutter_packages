import 'dart:convert';
import 'dart:io';

import 'package:common_extensions_utils/directory_extension.dart';
import 'package:common_extensions_utils/utils.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html_to_markdown/src/html_to_markdown/html_element_to_markdown/html_element_to_markdown.dart';
import 'package:path/path.dart' as p;

/// HTML to Markdown converter.
class HtmlToMarkdown {
  ///
  HtmlToMarkdown({
    required this.htmlDownloadsDir,
    required this.mdConversionsDir,
  });

  ///
  final Directory htmlDownloadsDir;

  ///
  final Directory mdConversionsDir;

  late String _websiteUrl;
  late String _contentContainerQuerySelector;
  late String? _specialH1QuerySelector;

  final _processedPagesData = <Map<String, String>>[];

  ///
  Future<void> convertFullWebsite(
    String websiteUrl,
    String contentContainerQuerySelector,
    String? specialH1QuerySelector,
  ) async {
    _websiteUrl = websiteUrl;
    _contentContainerQuerySelector = contentContainerQuerySelector;
    _specialH1QuerySelector = specialH1QuerySelector;

    // Delete previous converted content.
    if (mdConversionsDir.existsSync()) await mdConversionsDir.delete(recursive: true);

    // Convert all pages.
    for (final entity in htmlDownloadsDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.html')) {
        await _processHtmlFile(entity);
      }
    }

    // Copy all assets.
    final htmlAssetsDir = Directory(p.join(htmlDownloadsDir.path, 'assets'));
    if (htmlAssetsDir.existsSync()) {
      await htmlAssetsDir.copyContent(Directory(p.join(mdConversionsDir.path, 'assets')));
    }

    // Copy all menu-x.json files.
    var menuIndex = 0;
    var htmlMenuFile = File(p.join(htmlDownloadsDir.path, 'menu-$menuIndex.json'));
    while (htmlMenuFile.existsSync()) {
      await htmlMenuFile.copy(p.join(mdConversionsDir.path, 'menu-$menuIndex.json'));
      menuIndex++;
      htmlMenuFile = File(p.join(htmlDownloadsDir.path, 'menu-$menuIndex.json'));
    }

    // Save data to the pages.json file.
    await _savePagesJson(_processedPagesData);
  }

  Future<void> _processHtmlFile(File file) async {
    final html = await file.readAsString();

    final document = parse(html);

    if (document.body == null) return;

    // Get content container element.
    final element = document.body!.querySelector(_contentContainerQuerySelector);

    if (element == null) return;

    // var md = _htmlToMarkdown(element, 0);
    var md = HtmlElementToMarkdown().convert(
      element: element,
      plugin: _websiteUrl.contains('typescript')
          ? HtmlElementToMarkdownPlugin.typescript
          : HtmlElementToMarkdownPlugin.none,
    );

    // Remove the last double line break.
    md = md.substring(0, md.length - 1);

    if (_specialH1QuerySelector != null) {
      final h1Element = document.body!.querySelector(_specialH1QuerySelector!)!;
      // final h1Md = _htmlToMarkdown(h1Element, 0);
      final h1Md = HtmlElementToMarkdown().convert(
        element: h1Element,
        plugin: _websiteUrl.contains('typescript')
            ? HtmlElementToMarkdownPlugin.typescript
            : HtmlElementToMarkdownPlugin.none,
      );

      md = '# $h1Md\n\n$md';
    }

    _registerProcessedPageData(document, file.path);

    await _saveMarkdown(md, file.path);
  }

  // Register processed data.
  void _registerProcessedPageData(Document document, String pagePath) {
    final title = document.head!.querySelector('title')?.text ?? '';
    final description =
        document.head!.querySelector('meta[name="description"]')?.attributes['content'] ?? '';

    _processedPagesData.add(
      {
        'path': leftCleanLocalHtmlFilePath(pagePath, htmlDownloadsDir),
        'title': title,
        'description': description,
      },
    );
  }

  Future<void> _saveMarkdown(String md, String pagePath) async {
    final path = cleanLocalHtmlFilePath(pagePath, htmlDownloadsDir);

    final file = File(
      p.join(mdConversionsDir.path, '${path.substring(1)}.md'),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(md);
  }

  ///
  Future<void> _savePagesJson(List<Map<String, String>> pagesData) async {
    const encoder = JsonEncoder.withIndent('  ');

    final path = p.join(mdConversionsDir.path, 'pages.json');
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoder.convert(pagesData));
  }
}
