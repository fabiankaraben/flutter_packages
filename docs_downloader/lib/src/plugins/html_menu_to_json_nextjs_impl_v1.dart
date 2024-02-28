import 'package:collection/collection.dart';
import 'package:common_extensions_utils/html_extension.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:html/dom.dart';

/// Compatible with Next.js v14.1.
class HtmlMenuToJsonNextjsImplV1 implements HtmlMenuToJsonPlugin {
  ///
  @override
  String convertMenuToJson(Element element) {
    final uls = element.children.where((e) => e.localName == 'ul').toList();
    final usingAppRouterMenu = '<ul>'
        '${uls[0].children.first.outerHtml}'
        '${uls[1].children.first.outerHtml}'
        '${uls[2].children.first.outerHtml}'
        '${uls[5].children.first.outerHtml}'
        '${uls[6].children.first.outerHtml}'
        '</ul>';
    final usingPagesRouterMenu = '<ul>'
        '${uls[0].children.first.outerHtml}'
        '${uls[3].children.first.outerHtml}'
        '${uls[4].children.first.outerHtml}'
        '${uls[5].children.first.outerHtml}'
        '${uls[6].children.first.outerHtml}'
        '</ul>';
    final menuElement = Element.html(
      '<div><ul>'
      '<li><a href="">Using App Router</a><div><div>$usingAppRouterMenu</div></div></li>'
      '<li><a href="">Using Pages Router</a><div><div>$usingPagesRouterMenu</div></div></li>'
      '</ul></div>',
    );
    return _convertToJson(menuElement);
  }

  String _convertToJson(Element element) {
    final sf = StringBuffer();

    for (final node in element.nodes) {
      if (node.isTextNode) {
        if (node.trimedText.isNotEmpty) sf.write(node.text);
      } else if (node.isElementNode) {
        final el = node as Element;

        if (el.localName == 'ul') {
          sf.write(_convertUlOlToMd(el, 'ul'));
        } else if (el.localName == 'li') {
          sf.write(_convertLiToMd(el));
        } else if (el.localName == 'div') {
          sf.write(_convertDivToMd(el));
        }
      }
    }

    return sf.toString();
  }

  // Block level element.
  String _convertUlOlToMd(Element element, String listType) {
    const pre = '[';
    final inner = _convertToJson(element);
    const post = ']';

    return '$pre$inner$post'.replaceFirst('},]', '}]');
  }

  // Block level element.
  String _convertLiToMd(Element element) {
    const pre = '{';
    final anchorEl = element.children.firstWhere((e) => e.localName == 'a');

    final div1El = element.children.firstWhereOrNull((e) => e.localName == 'div');
    final div2El = div1El?.children.firstWhereOrNull((e) => e.localName == 'div');
    final ulEl = div2El?.children.firstWhereOrNull((e) => e.localName == 'ul');

    final path = anchorEl.attributes['href'] ?? '';
    final inner = '"title":"${anchorEl.text}"'
        ',"path":"$path"'
        '${ulEl != null ? ',"items":${_convertToJson(div2El!)}' : ''}';

    const post = '},';

    return '$pre$inner$post';
  }

  String _convertDivToMd(Element element) {
    const pre = '';
    final inner = _convertToJson(element);
    const post = '';

    return '$pre$inner$post';
  }
}
