import 'dart:convert';
import 'dart:io';

import 'package:common_extensions/html_extension.dart';
import 'package:common_extensions/utils.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:docs_downloader/src/utils/path.dart';
import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

///
class HtmlMenuToJsonTypeScriptImpl implements HtmlMenuToJsonPlugin {
  ///
  @override
  String convertMenuToJson(Element element, String pagePath) {
    return _convertToJson(element, pagePath);
  }

  String _convertToJson(Element element, String pagePath) {
    final sf = StringBuffer();

    for (final node in element.nodes) {
      if (node.isTextNode) {
        if (node.trimedText.isNotEmpty) sf.write(node.text);
      } else if (node.isElementNode) {
        final el = node as Element;

        if (el.localName == 'ul') {
          sf.write(_convertUlOlToMd(el, 'ul', pagePath));
        } else if (el.localName == 'li') {
          sf.write(_convertLiToMd(el, pagePath));
        }
      }
    }

    return sf.toString();
  }

  // Block level element.
  String _convertUlOlToMd(Element element, String listType, String pagePath) {
    const pre = '[';
    final inner = _convertToJson(element, pagePath);
    const post = ']';

    return '$pre$inner$post'.replaceFirst('},]', '}]');
  }

  // Block level element.
  String _convertLiToMd(Element element, String pagePath) {
    const pre = '{';
    var inner = '';
    final anchorEl = element.children.firstWhere(
      (e) => e.localName == 'a',
      orElse: () => Element.tag('not-found'),
    );
    if (anchorEl.localName != 'not-found') {
      final path = leftCleanSourcePath(anchorEl.attributes['href'] ?? '', pagePath);
      inner = '"title":"${anchorEl.text}","path":"$path"';
    } else {
      final buttonEl = element.children.firstWhere((e) => e.localName == 'button');
      inner = '"title":"${buttonEl.text}","path":"","items":${_convertToJson(element, pagePath)}';
    }
    const post = '},';

    return '$pre$inner$post';
  }

  ///
  @override
  Future<void> saveJsonMenu(
    String stringJsonMenu,
    Directory htmlDownloadsDir,
    String websiteUrl,
    int menuIdx,
  ) async {
    final jsonMenu = List<Map<dynamic, dynamic>>.from(
      jsonDecode(stringJsonMenu) as Iterable,
    );

    void cleanInOrder(List<Map<dynamic, dynamic>> items) {
      for (final item in items) {
        if (item['path'] != null && (item['path'] as String).trim().isNotEmpty) {
          item['path'] = leftCleanSourcePath(
            getPathWithoutArchiveOrg(item['path'] as String),
            websiteUrl,
          );
        }
        if (item['items'] != null) {
          cleanInOrder(List<Map<dynamic, dynamic>>.from(item['items'] as Iterable));
        }
      }
    }

    // Clean all the paths.
    cleanInOrder(jsonMenu);

    const encoder = JsonEncoder.withIndent('  ');

    final path = p.join(htmlDownloadsDir.path, 'menu-$menuIdx.json');
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoder.convert(jsonMenu));
  }
}
