import 'package:common_extensions_utils/html_extension.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:html/dom.dart';

/// Compatible with React v18.0, v18.1.
class HtmlMenuToJsonReactImplV1 implements HtmlMenuToJsonPlugin {
  ///
  @override
  String convertMenuToJson(Element element) {
    return '[${_convertToJson(element)}]'.replaceFirst('},]', '}]');
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
    final path = anchorEl.attributes['href'] ?? '';
    final inner = '"title":"${anchorEl.text}","path":"$path"';
    const post = '},';

    return '$pre$inner$post';
  }

  String _convertDivToMd(Element element) {
    const pre = '{';
    final buttonEl = element.children.firstWhere((e) => e.localName == 'button');
    final inner = '"title":"${buttonEl.text}","path":"","items":${_convertToJson(element)}';
    const post = '},';

    return '$pre$inner$post';
  }
}
