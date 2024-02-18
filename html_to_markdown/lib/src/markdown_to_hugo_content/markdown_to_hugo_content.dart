import 'dart:convert';
import 'dart:io';

import 'package:common_extensions_utils/directory_extension.dart';
import 'package:common_extensions_utils/utils.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/menu_item.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/models/page.dart';
import 'package:html_to_markdown/src/markdown_to_hugo_content/data/repositories/menu_items_and_pages_repository.dart';
import 'package:path/path.dart' as p;

///
class MarkdownToHugoContent {
  ///
  MarkdownToHugoContent({
    required this.mdConversionsDir,
    required this.hugoContentBaseDir,
    required this.websiteBuildDirectoryName,
    this.versionBuildDirectoryName,
  });

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
  late String _websiteUrl;

  ///
  Future<void> convertFullWebsite({
    required String websiteTitle,
    required String websiteUrl,
  }) async {
    _websiteUrl = websiteUrl;

    final hasVersion = versionBuildDirectoryName != null;

    // If Hugo 'static' directory exists hugoContentBaseDir is for a final Hugo content,
    // otherwise it is for another intermediate step, it is an all-in-one directory.
    final existsHugoStaticDir = Directory(
      p.join(hugoContentBaseDir.parent.path, 'static'),
    ).existsSync();

    // Get required data.
    final (ms, ps) = await MenuItemsAndPagesRepository().menuItemsAndPages(
      mdConversionsDir: mdConversionsDir,
      websiteBuildDirectoryName: websiteBuildDirectoryName,
      websiteTitle: websiteTitle,
      hasVersion: hasVersion,
    );
    _menuItems = ms;
    _pages = ps;

    // for (final menuItem in _menuItems) {
    //   print(menuItem);
    // }

    // for (final page in _pages) {
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
    if (existsHugoStaticDir) {
      if (rootItemDirectory.existsSync()) await rootItemDirectory.delete(recursive: true);
    } else {
      if (hugoContentBaseDir.existsSync()) await hugoContentBaseDir.delete(recursive: true);
    }

    // Recursively create menu directories, subdirectories and its _index.md files.
    await _addIndexFileToDirectory(
      hasVersion ? rootItemDirectory.parent : rootItemDirectory,
      rootMenuItem,
    );

    //
    // Build content files.
    //

    for (final page in _pages) {
      if (_menuItemDirectoriesById.containsKey(page.menuItemId)) {
        final enFileRelPath =
            '${cleanLocalHtmlFilePath(page.path, mdConversionsDir).substring(1)}.md';
        final mdFile = File(p.join(mdConversionsDir.path, enFileRelPath));

        if (!mdFile.existsSync()) continue;

        await _processMdFile(
          page,
          mdFile,
          _menuItemDirectoriesById[page.menuItemId]!,
        );
      }
    }

    //
    // Copy website data directory.
    //

    if (!existsHugoStaticDir) {
      // Copy website data (assets and JSON files).
      final websiteDataDir = Directory(p.join(mdConversionsDir.path, 'website-data-82361054'));
      if (websiteDataDir.existsSync()) {
        await websiteDataDir.copyContent(
          Directory(p.join(hugoContentBaseDir.path, 'website-data-82361054')),
        );
      }
    } else {
      // Copy all assets.
      final assetsDir = Directory(
        p.join(mdConversionsDir.path, 'website-data-82361054', 'assets'),
      );
      if (assetsDir.existsSync()) {
        final staticAssetsDir = Directory(
          p.join(
            hugoContentBaseDir.parent.path,
            'static',
            'assets',
            websiteBuildDirectoryName,
            versionBuildDirectoryName,
          ),
        );
        if (staticAssetsDir.existsSync()) await staticAssetsDir.delete(recursive: true);
        await assetsDir.copyContent(staticAssetsDir);
      }
    }
  }

  Future<void> _processMdFile(Page page, File sourceFile, Directory finalFileDirectory) async {
    var md = await sourceFile.readAsString();

    final prevPageParameter = _frontMatterPrevParameterValue(page);
    final nextPageParameter = _frontMatterNextParameterValue(page);

    // Add new front matter.
    md = [
      '---',
      'linkTitle: "${page.linkTitle}"',
      'title: "${page.title}"',
      'description: "${page.description}"',
      'weight: ${page.weight}',
      'type: docs',
      if (prevPageParameter != null) 'prev: $prevPageParameter',
      if (nextPageParameter != null) 'next: $nextPageParameter',
      '---',
      '',
      md,
    ].join('\n');

    // Adapt assets paths (images, ...).
    md = await _convertAllPageAssetPaths(
      md,
      websiteBuildDirectoryName,
      versionBuildDirectoryName,
    );

    // Adapt all links.
    md = await _adaptAllLinkPaths(md);

    await _saveMarkdown(page, md, finalFileDirectory);
  }

  String? _frontMatterPrevParameterValue(Page page) {
    final minWeightPage = _pages
        .where((e) => e.menuItemId == page.menuItemId)
        .reduce((current, next) => current.weight < next.weight ? current : next);
    if (minWeightPage.id == page.id) {
      final idxOfPath = _inOrderPathPaths.indexOf(page.path);
      if (idxOfPath < 1 || idxOfPath == _inOrderPathPaths.length - 1) return null;
      final prevPage = _pages.firstWhere((e) => e.path == _inOrderPathPaths[idxOfPath - 1]);
      if (_menuItemDirectoriesById.containsKey(prevPage.menuItemId)) {
        return _getFullSlugPagePath(prevPage.path);
      }
    }
    return null;
  }

  String? _frontMatterNextParameterValue(Page page) {
    final maxWeightPage = _pages
        .where((e) => e.menuItemId == page.menuItemId)
        .reduce((current, next) => current.weight > next.weight ? current : next);
    if (maxWeightPage.id == page.id) {
      final idxOfPath = _inOrderPathPaths.indexOf(page.path);
      if (idxOfPath < 1 || idxOfPath == _inOrderPathPaths.length - 1) return null;
      final nextPage = _pages.firstWhere((e) => e.path == _inOrderPathPaths[idxOfPath + 1]);
      if (_menuItemDirectoriesById.containsKey(nextPage.menuItemId)) {
        return _getFullSlugPagePath(nextPage.path);
      }
    }
    return null;
  }

  Future<List<String>> _getInOrderPagePathsFromMenuJsonFile() async {
    final path = p.join(mdConversionsDir.path, 'website-data-82361054', 'menu-0.json');

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

    final redirect = _frontMatterRedirectParameterValue(menuItem);

    final indexFile = File(p.join(directory.path, '_index.md'));
    await indexFile.parent.create(recursive: true);
    await indexFile.writeAsString(
      [
        '---',
        'title: ${menuItem.title}',
        if (menuItem.parentId != null) 'weight: ${menuItem.weight}',
        'type: docs',
        if (redirect != null) 'redirect: $redirect',
        'noindex: true',
        '---',
        '',
      ].join('\n'),
    );
  }

  String? _frontMatterRedirectParameterValue(MenuItem menuItem) {
    var levelCount = 0;
    var currentMenuItem = menuItem;

    while (levelCount < 15) {
      levelCount++;
      final menuItemPages = _pages.where((e) => e.menuItemId == currentMenuItem.id);
      if (menuItemPages.isEmpty) {
        final menuSubitems = _menuItems.where((e) => e.parentId == currentMenuItem.id);
        if (menuSubitems.isEmpty) break;
        currentMenuItem = menuSubitems.reduce(
          (current, next) => current.weight < next.weight ? current : next,
        );
        continue;
      }

      final minWeightPage = menuItemPages.reduce(
        (current, next) => current.weight < next.weight ? current : next,
      );

      return _getFullSlugPagePath(minWeightPage.path);
    }

    return null;
  }

  /// Adapt all asset paths for this page.
  Future<String> _convertAllPageAssetPaths(
    String md,
    String websiteBuildDirectoryName,
    String? versionBuildDirectoryName,
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
          p.join('/assets', websiteBuildDirectoryName, versionBuildDirectoryName),
          '/',
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

  //
  Future<String> _adaptAllLinkPaths(String md) async {
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
      } else if (path.startsWith('http')) {
        mdSB.writeAll([
          // External path (keep with no modifications).
          md.substring(preTextStart, pathStart - 2),
          ' ↗](',
          path,
        ]);
      } else {
        final cleanPath = rightCleanSourcePath(path);
        final pathFragment = path.contains('#') ? path.substring(path.indexOf('#')) : '';
        mdSB.writeAll(
          _pages.any((e) => e.path == cleanPath)
              ? [
                  // Internal path.
                  md.substring(preTextStart, pathStart),
                  '${_getFullSlugPagePath(cleanPath)}$pathFragment',
                ]
              : [
                  // Internal path not included in the menu.
                  md.substring(preTextStart, pathStart - 2),
                  ' ↗](',
                  '$_websiteUrl$path',
                ],
        );
      }
      preTextStart = pathEnd;
      pathStart = md.indexOf('](', pathEnd);
    }
    mdSB.write(md.substring(preTextStart, md.length));

    return mdSB.toString();
  }

  // [path] must be a root relative path without query and without fragment.
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
