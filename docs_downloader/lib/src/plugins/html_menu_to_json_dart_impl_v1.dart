import 'package:collection/collection.dart';
import 'package:common_extensions_utils/html_extension.dart';
import 'package:docs_downloader/src/plugins/html_menu_to_json.dart';
import 'package:html/dom.dart';

///
class HtmlMenuToJsonDartImplV1 implements HtmlMenuToJsonPlugin {
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
    final anchorEl = element.children.firstWhereOrNull((e) => e.localName == 'a');
    late String inner;
    if (anchorEl == null) {
      return '';
    } else {
      final title = anchorEl.text.trim();
      final ulEl = element.children.firstWhereOrNull((e) => e.localName == 'ul');
      final path = ulEl == null ? anchorEl.attributes['href'] ?? '' : '';
      final items = ulEl != null ? '[${_convertToJson(ulEl)}]'.replaceFirst('},]', '}]') : '';

      inner = '"title":"$title", "path":"$path"${ulEl != null ? ', "items":$items' : ''}';
    }
    const post = '},';

    return '$pre$inner$post';
  }
}
