import 'package:common_extensions_utils/html_extension.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:html/dom.dart';

///
class HtmlMenuToJsonTypeScriptImpl implements HtmlMenuToJsonPlugin {
  ///
  @override
  String convertMenuToJson(Element element) {
    return _convertToJson(element);
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
    var inner = '';
    final anchorEl = element.children.firstWhere(
      (e) => e.localName == 'a',
      orElse: () => Element.tag('not-found'),
    );
    if (anchorEl.localName != 'not-found') {
      final path = anchorEl.attributes['href'] ?? '';
      inner = '"title":"${anchorEl.text}","path":"$path"';
    } else {
      final buttonEl = element.children.firstWhere((e) => e.localName == 'button');
      inner = '"title":"${buttonEl.text}","path":"","items":${_convertToJson(element)}';
    }
    const post = '},';

    return '$pre$inner$post';
  }
}
