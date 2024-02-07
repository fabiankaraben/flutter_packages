import 'dart:convert';
import 'dart:io';

import 'package:common_extensions/utils.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/repositories/menu_items_repository.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/repositories/pages_repository.dart';
import 'package:path/path.dart' as p;

///
class MarkdownToHugoContent {
  ///
  MarkdownToHugoContent({
    required this.htmlDownloadsDir,
    required this.mdConversionsDir,
    required this.hugoContentBaseDir,
    required this.websiteBuildDirectoryName,
    this.versionBuildDirectoryName,
  });

  ///
  final Directory htmlDownloadsDir;

  ///
  final Directory mdConversionsDir;

  ///
  final Directory hugoContentBaseDir;

  ///
  final String websiteBuildDirectoryName;

  ///
  final String? versionBuildDirectoryName;

  ///
  late List<MenuItem> _menuItems;

  ///
  late List<Page> _pages;

  ///
  final Map<int, Directory> _menuItemDirectoriesById = {};

  ///
  late List<String> _inOrderPathPaths;

  ///
  Future<void> convertFullWebsite({
    required String websiteTitle,
    required String websiteUrl,
  }) async {
    // Get required data.
    _menuItems = await MenuItemsRepository().menuItems(
      htmlDownloadsDir: htmlDownloadsDir,
      websiteTitle: websiteTitle,
    );
    _pages = await PagesRepository().pages(htmlDownloadsDir: htmlDownloadsDir);

    // for (final menuItem in menuItems) {
    //   print(menuItem);
    // }

    // for (final page in pages) {
    //   print(page);
    // }

    // Get an in order list of paths of pages from the menu.json file.
    _inOrderPathPaths = await _getInOrderPagePathsFromMenuJsonFile();

    //
    // Create menu structure.
    //

    final rootMenuItem = _menuItems.where((e) => e.parentId == null).first;
    final rootItemDirectory = Directory(
      p.join(hugoContentBaseDir.path, websiteBuildDirectoryName, versionBuildDirectoryName),
    );

    // Delete previous website content directory.
    if (rootItemDirectory.existsSync()) await rootItemDirectory.delete(recursive: true);

    // Recursively create menu directories, subdirectories and its _index.md files.
    await _addIndexFileToDirectory(rootItemDirectory, rootMenuItem);

    //
    // Build content files.
    //

    for (final page in _pages) {
      if (_menuItemDirectoriesById.containsKey(page.menuItemId)) {
        final enFileRelPath =
            '${cleanLocalHtmlFilePath(page.path, htmlDownloadsDir).substring(1)}.md';
        await _processMdFile(
          page,
          File(p.join(mdConversionsDir.path, enFileRelPath)),
          _menuItemDirectoriesById[page.menuItemId]!,
        );
      }
    }

    //
    // Adapt all links.
    //

    // for (final page in _pages) {
    //   await _adaptAllLinkPaths(
    //     websiteUrl,
    //     page,
    //     _menuItemDirectoriesById[page.menuItemId]!,
    //   );
    // }
  }

  Future<void> _processMdFile(Page page, File sourceFile, Directory finalFileDirectory) async {
    var md = await sourceFile.readAsString();

    final prevPageParameter = _prevPageParameter(page);
    final nextPageParameter = _nextPageParameter(page);

    // Add new front matter.
    md = [
      '---',
      'linkTitle: "${page.linkTitle}"',
      'title: "${page.title}"',
      'description: "${page.description}"',
      'weight: ${page.weight}',
      'type: docs',
      if (prevPageParameter != null) prevPageParameter,
      if (nextPageParameter != null) nextPageParameter,
      '---',
      '',
      md,
    ].join('\n');

    // Adapt assets paths (images, ...).
    md = await _convertAllPageAssetPaths(
      md,
      websiteBuildDirectoryName,
      versionBuildDirectoryName!,
    );

    await _saveMarkdown(page, md, finalFileDirectory);
  }

  String? _prevPageParameter(Page page) {
    final minWeightPage = _pages
        .where((e) => e.menuItemId == page.menuItemId)
        .reduce((current, next) => current.weight < next.weight ? current : next);
    if (minWeightPage.id == page.id) {
      final idxOfPath = _inOrderPathPaths.indexOf(page.path);
      if (idxOfPath < 1 || idxOfPath == _inOrderPathPaths.length - 1) return null;
      final prevPage = _pages.firstWhere((e) => e.path == _inOrderPathPaths[idxOfPath - 1]);
      if (_menuItemDirectoriesById.containsKey(prevPage.menuItemId)) {
        return 'prev: ${_getFullSlugPath(prevPage)}';
      }
    }
    return null;
  }

  String? _nextPageParameter(Page page) {
    final maxWeightPage = _pages
        .where((e) => e.menuItemId == page.menuItemId)
        .reduce((current, next) => current.weight > next.weight ? current : next);
    if (maxWeightPage.id == page.id) {
      final idxOfPath = _inOrderPathPaths.indexOf(page.path);
      if (idxOfPath < 1 || idxOfPath == _inOrderPathPaths.length - 1) return null;
      final nextPage = _pages.firstWhere((e) => e.path == _inOrderPathPaths[idxOfPath + 1]);
      if (_menuItemDirectoriesById.containsKey(nextPage.menuItemId)) {
        return 'next: ${_getFullSlugPath(nextPage)}';
      }
    }
    return null;
  }

  String _getFullSlugPath(Page page) {
    if (page.menuItemId == null) return '';
    String find(int menuItemId) {
      final item = _menuItems.firstWhere((e) => e.id == menuItemId);
      if (item.parentId == null) return '/${item.slug}';
      return '${find(item.parentId!)}/${item.slug}';
    }

    return '${find(page.menuItemId!)}/${page.slug}';
  }

  Future<List<String>> _getInOrderPagePathsFromMenuJsonFile() async {
    final path = p.join(htmlDownloadsDir.path, 'menu-0.json');

    final json = List<Map<dynamic, dynamic>>.from(
      jsonDecode(await File(path).readAsString()) as Iterable,
    );

    final paths = <String>[];

    void inOrder(List<Map<dynamic, dynamic>> items) {
      for (final item in items) {
        if (item['path'] != null && (item['path'] as String).trim().isNotEmpty) {
          paths.add(item['path'] as String);
        }
        if (item['items'] != null) {
          inOrder(List<Map<dynamic, dynamic>>.from(item['items'] as Iterable));
        }
      }
    }

    inOrder(json);

    return paths;
  }

  Future<void> _saveMarkdown(Page page, String mdContent, Directory finalFileDirectory) async {
    final file = File(p.join(finalFileDirectory.path, '${page.slug}.md'));
    await file.writeAsString(mdContent);
  }

  // Add '_index.md' file to the directory.
  Future<void> _addIndexFileToDirectory(Directory directory, MenuItem menuItem) async {
    // Register directory path to be used in processing content files.
    _menuItemDirectoriesById[menuItem.id] = directory;

    // Add '_index.md' file to subdirectories of this menu item.
    final subItems = _menuItems.where((e) => e.parentId == menuItem.id);
    if (subItems.isNotEmpty) {
      for (final subItem in subItems) {
        final subItemDir = Directory(p.join(directory.path, subItem.slug));
        await _addIndexFileToDirectory(subItemDir, subItem);
      }
    }

    final indexFile = File(p.join(directory.path, '_index.md'));
    await indexFile.parent.create(recursive: true);
    await indexFile.writeAsString(
      [
        '---',
        'title: ${menuItem.title}',
        if (menuItem.parentId != null) 'weight: ${menuItem.weight}',
        'type: docs',
        'noindex: true',
        '---',
        '',
      ].join('\n'),
    );
  }

  /// Adapt all asset paths for this page.
  Future<String> _convertAllPageAssetPaths(
    String md,
    String websiteBuildDirectoryName,
    String versionBuildDirectoryName,
  ) async {
    //
    // Create a list of all images paths on content.
    //

    final imgPaths = <String>[];
    var imgStart = md.indexOf('![');
    while (imgStart != -1) {
      final pathStart = md.indexOf('](', imgStart) + 2;
      final pathEnd = md.indexOf(')', pathStart);
      imgPaths.add(md.substring(pathStart, pathEnd));
      imgStart = md.indexOf('![', pathEnd);
    }

    //
    // Replace paths on content.
    //

    final mdSB = StringBuffer();
    var preTextStart = 0;
    imgStart = md.indexOf('![');
    var pathIdx = 0;
    while (imgStart != -1) {
      final pathStart = md.indexOf('](', imgStart) + 2;
      final pathEnd = md.indexOf(')', pathStart);
      mdSB.writeAll(
        [
          md.substring(preTextStart, pathStart),
          '/assets/$websiteBuildDirectoryName/$websiteBuildDirectoryName',
          imgPaths[pathIdx].substring('/assets/'.length),
        ],
      );
      preTextStart = pathEnd;
      imgStart = md.indexOf('![', pathEnd);
      pathIdx++;
    }
    mdSB.write(md.substring(preTextStart));

    return mdSB.toString();
  }

  Future<void> _adaptAllLinkPaths(
    String websiteUrl,
    Page page,
    Directory finalFileDirectory,
  ) async {
    //
    // Get.
    //

    final file = File(p.join(finalFileDirectory.path, '${page.slug}.md'));
    final md = await file.readAsString();

    //
    // Replace translated paths on spanish content.
    //

    final mdSB = StringBuffer();
    var preTextStart = 0;
    var pathStart = md.indexOf('](');
    while (pathStart != -1) {
      pathStart += 2; // Avoiding the '](' part.
      final pathEnd = md.indexOf(')', pathStart);
      final path = md.substring(pathStart, pathEnd);

      var isImage = false;
      for (var i = pathStart; i > 0; i--) {
        if (md[i] == '[' && md[i - 1] == '!') {
          isImage = true;
          break;
        }
      }

      if (isImage) {
        mdSB.writeAll([
          // Image (keep with no modifications).
          md.substring(preTextStart, pathStart),
          path,
        ]);
      } else {
        final cleanPath = leftRightCleanSourcePath(path, websiteUrl);
        mdSB.writeAll(
          // fullTranslatedPagePaths.contains(cleanPath) && cleanPath.startsWith('/')
          //     ?
          [
            // Full translated path.
            md.substring(preTextStart, pathStart),
            _getFullSlugPagePath(cleanPath),
          ],
          // : [
          //     // Not full translated path.
          //     md.substring(preTextStart, pathStart - 2),
          //     ' ↗](',
          //     if (path.startsWith('/')) '${website.sourceUrl}$path' else path,
          //   ],
        );
      }
      preTextStart = pathEnd;
      pathStart = md.indexOf('](', pathEnd);
    }
    mdSB.write(md.substring(preTextStart, md.length));

    //
    // Save.
    //

    await _saveMarkdown(page, mdSB.toString(), finalFileDirectory);
  }

  String _getFullSlugPagePath(String path) {
    final page = _pages.firstWhere((e) => e.path == path);
    var menuItem = _menuItems.firstWhere((e) => e.id == page.menuItemId);
    final slugs = <String>[page.slug, menuItem.slug];
    while (menuItem.parentId != null) {
      menuItem = _menuItems.firstWhere((e) => e.id == menuItem.parentId);
      slugs.add(menuItem.slug);
    }
    return '/${slugs.reversed.join('/')}';
  }
}
