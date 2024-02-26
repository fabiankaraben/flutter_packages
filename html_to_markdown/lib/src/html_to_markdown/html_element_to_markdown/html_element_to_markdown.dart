import 'package:common_extensions_utils/html_extension.dart';
import 'package:html/dom.dart';
import 'package:html_to_markdown/src/html_to_markdown/html_element_to_markdown/plugins/typescript.dart';

///
enum HtmlElementToMarkdownPlugin {
  ///
  none,

  ///
  typescript,
}

/// HTML to Markdown converter.
class HtmlElementToMarkdown {
  late HtmlElementToMarkdownPlugin _plugin;

  /// Class level global context for the recursive execution of [_htmlToMarkdown].
  final Map<String, dynamic> _context = {};

  ///
  String convert({
    required Element element,
    required HtmlElementToMarkdownPlugin plugin,
  }) {
    _plugin = plugin;
    return _htmlToMarkdown(element, 0);
  }

  String _htmlToMarkdown(Element element, int level) {
    final md = StringBuffer();

    for (final node in element.nodes) {
      if (node.isTextNode) {
        if (_context.containsKey('pre') || node.trimedText.isNotEmpty) md.write(node.text);
      } else if (node.isElementNode) {
        final el = node as Element;

        //
        // Block level elements.
        //

        if ({'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}.contains(el.localName)) {
          md.write(_convertHeadingToMd(el, level));
        } else if (el.localName == 'p') {
          md.write(_convertParagraphToMd(el, level));
        } else if (el.localName == 'div') {
          md.write(_convertDivToMd(el, level));
        } else if (el.localName == 'header') {
          md.write(_convertHeaderToMd(el, level));
        } else if (el.localName == 'blockquote') {
          md.write(_convertBlockquoteToMd(el, level));
        } else if (el.localName == 'hr') {
          md.write(_convertHrToMd(el, level));
        } else if (el.localName == 'figure') {
          md.write(_convertFigureToMd(el, level));
        } else if (el.localName == 'pre') {
          if (_plugin == HtmlElementToMarkdownPlugin.typescript) {
            md.write(HtmlToMdTypeScript.convertPreToMd(el, level, _htmlToMarkdown, _context));
          } else {
            md.write(_convertPreToMd(el, level));
          }
        } else if (el.localName == 'ul') {
          md.write(_convertUlOlToMd(el, level, 'ul'));
        } else if (el.localName == 'ol') {
          md.write(_convertUlOlToMd(el, level, 'ol'));
        } else if (el.localName == 'li') {
          md.write(_convertLiToMd(el, level));
        } else if (el.localName == 'table') {
          md.write(_convertTableToMd(el, level));
        } else if (el.localName == 'thead') {
          md.write(_convertTHeadToMd(el, level));
        } else if (el.localName == 'tbody') {
          md.write(_convertTBodyToMd(el, level));
        } else if (el.localName == 'tr') {
          md.write(_convertTrToMd(el, level));
        } else if (el.localName == 'th') {
          md.write(_convertThToMd(el, level));
        } else if (el.localName == 'td') {
          md.write(_convertTdToMd(el, level));
        }

        //
        // Inline level elements.
        //

        if (el.localName == 'a') {
          md.write(_convertAnchorToMd(el, level));
        } else if (el.localName == 'span') {
          md.write(_convertSpanToMd(el, level));
        } else if (el.localName == 'strong' || el.localName == 'b') {
          md.write(_convertStrongToMd(el, level));
        } else if (el.localName == 'em' || el.localName == 'i') {
          md.write(_convertEmToMd(el, level));
        } else if (el.localName == 'img') {
          md.write(_convertImgToMd(el, level));
        } else if (el.localName == 'code') {
          md.write(_convertCodeToMd(el, level));
        } else if (el.localName == 'br') {
          // md.write(_convertDivToMd(el, level));
        }

        //
        // Elements from plugins.
        //

        if (_plugin == HtmlElementToMarkdownPlugin.typescript) {
          HtmlToMdTypeScript().addExtraConvertions(el, level, md, _htmlToMarkdown, _context);
        }
      }
    }

    return md.toString();
  }

  // Block level element.
  String _convertHeadingToMd(Element element, int level) {
    final pre = '${'#' * int.parse(element.localName![1])} ';
    var inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );
    const post = '\n\n';

    //
    // Get the text value.
    //

    var text = '';
    if (inner.contains('](')) {
      final middle = inner.indexOf('](');
      final start = inner.lastIndexOf('[', middle);
      final end = inner.indexOf(')', middle);
      final linkText = inner.substring(start + 1, middle).trim();
      text = linkText.isNotEmpty
          ? linkText
          : '${inner.substring(0, start)}${inner.substring(end + 1, inner.length)}';
    } else {
      text = inner;
    }

    //
    // Get the id value.
    //

    var id = '';

    // Get possible id from inner anchor elements id.
    for (final anchorEl in element.querySelectorAll('a')) {
      if (id.isEmpty && anchorEl.attributes['id'] != null) {
        id = anchorEl.attributes['id']!;
      }
    }

    // Get possible id from 'h_' element id.
    if (id.isEmpty && element.attributes['id'] != null) {
      id = element.attributes['id']!;
    }

    // Get possible id from inner anchor elements href.
    if (id.isEmpty) {
      var start = inner.indexOf('(');
      while (start != -1 && id.isEmpty) {
        final end = inner.indexOf(')', start);
        final parenthesisText = inner.substring(start + 1, end);

        if (parenthesisText.contains('#')) {
          // Remove possible path.
          id = parenthesisText.split('#').last;
          // Remove possible URL params.
          if (id.contains('?')) id = id.split('?').first;
        }

        start = inner.indexOf('(', end);
      }
    }

    //
    // Merge text and id.
    //

    inner = '${text.trim()}${id.isNotEmpty ? ' {#$id}' : ''}';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertParagraphToMd(Element element, int level) {
    const pre = '';
    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );
    final post = level == 0 ? '\n\n' : '\n';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertDivToMd(Element element, int level) {
    const pre = '';

    if (element.attributes.containsKey('data-language')) {
      _context['div_data-language'] = element.attributes['data-language'];
    }

    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );

    _context.remove('pre');

    final post = level == 0 ? '\n\n' : '\n';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertHeaderToMd(Element element, int level) {
    const pre = '';
    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );
    final post = level == 0 ? '\n\n' : '\n';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertBlockquoteToMd(Element element, int level) {
    const pre = '> ';
    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1).replaceAll('\n', '\n> '),
    );
    final post = level == 0 ? '\n\n' : '\n';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertHrToMd(Element element, int level) {
    return '---\n\n';
  }

  // Block level element.
  String _convertFigureToMd(Element element, int level) {
    const pre = '';
    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );
    final post = level == 0 ? '\n\n' : '\n';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertPreToMd(Element element, int level) {
    final insideTr = _context.containsKey('tr');
    final insideCode = _context.containsKey('code');
    final startEndChars = insideCode ? '``' : '```';

    var lang = '';
    if (_context.containsKey('div_data-language')) {
      lang = _context['div_data-language'] as String;
    }

    final pre = '$startEndChars$lang\n';
    _context['pre'] = true;
    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );
    _context.remove('pre');
    final post = level == 0
        ? '\n$startEndChars\n\n'
        : (insideCode ? '\n$startEndChars' : '\n$startEndChars\n');

    if (insideTr) {
      return '<div class="code-block relative mt-6 first:mt-0 group/code"><pre><code>'
          '$inner'
          '</code></pre></div>';
    }

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertUlOlToMd(Element element, int level, String listType) {
    const pre = '';
    final listLevel = _context.containsKey('list-level') ? (_context['list-level'] as int) + 1 : 0;
    _context['list-level'] = listLevel;
    _context['$listType-$listLevel-index'] = 1;
    final inner = _removeAllLastLineBreaks(
      _htmlToMarkdown(element, level + 1),
    );
    _context.remove('$listType-$listLevel-index');
    if (_context['list-level'] == 0) {
      _context.remove('list-level');
    } else {
      _context['list-level'] = (_context['list-level'] as int) - 1;
    }

    final post = level == 0 ? '\n\n' : '\n';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertLiToMd(Element element, int level) {
    final listLevel = _context['list-level'] as int;
    final type = _context.containsKey('ol-$listLevel-index') ? 'ol' : 'ul';
    final index = _context['$type-$listLevel-index'] as int;
    final pre = type == 'ul' ? '- ' : '$index. ';
    _context['li'] = true;
    var inner = _removeAllLastLineBreaks(
      _addTabToLiInner(
        _htmlToMarkdown(element, level + 1),
      ),
    );
    _context['$type-$listLevel-index'] = index + 1;
    _context.remove('li');
    const post = '\n';

    // Add extra padding (new lines) to code blocks inside a list element.
    if (inner.contains('```')) {
      var isCodeBlockOpen = false;
      final innerSB = StringBuffer();
      for (final line in inner.split('\n')) {
        if (line.trim().startsWith('```') && !isCodeBlockOpen) {
          innerSB.writeAll(['\n', line, '\n']);
          isCodeBlockOpen = true;
        } else if (line.trim().startsWith('```') && isCodeBlockOpen) {
          innerSB.writeAll([line, '\n']);
          isCodeBlockOpen = false;
        } else {
          innerSB.writeAll([line, '\n']);
        }
      }
      inner = innerSB.toString();
    }

    return '$pre$inner$post';
  }

  String _addTabToLiInner(String inner) {
    if (_context.containsKey('list-level')) {
      final lines = inner.split('\n');
      for (var i = 1; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) lines[i] = '  ${lines[i]}';
      }
      return lines.join('\n');
    }
    return inner;
  }

  // Block level element.
  String _convertTableToMd(Element element, int level) {
    const pre = '';
    _context['table'] = true;
    _context['num-tr'] = element.querySelectorAll('tr').length;
    _context['tr-index'] = 0;
    _context['num-th'] = element.querySelectorAll('th').length;
    _context['num-td'] = element.querySelectorAll('td').length;
    final inner = _htmlToMarkdown(element, level + 1);
    _context
      ..remove('table')
      ..remove('num-tr')
      ..remove('tr-index')
      ..remove('num-th')
      ..remove('num-td');
    final post = level == 0 ? '\n\n' : '\n';
    return '$pre$inner$post';
  }

  // Block level element.
  String _convertTHeadToMd(Element element, int level) {
    const pre = '';
    _context['thead'] = true;
    final inner = _htmlToMarkdown(element, level + 1);
    _context.remove('thead');
    const post = '';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertTBodyToMd(Element element, int level) {
    const pre = '';
    _context['tbody'] = true;
    final inner = _htmlToMarkdown(element, level + 1);
    _context.remove('tbody');
    const post = '';

    return '$pre$inner$post';
  }

  // Block level element.
  String _convertTrToMd(Element element, int level) {
    const pre = '|';
    _context['tr'] = true;
    var inner = _htmlToMarkdown(element, level + 1).replaceAll('\n', '<br>');
    _context.remove('tr');
    var post = '\n';

    if (_context['tr-index'] == 0) {
      post = '\n${'|---' * (_context['num-th'] as int)}|\n';
    }

    _context['tr-index'] = (_context['tr-index'] as int) + 1;

    // When there is a <pre> inside a <code> inside a table cell.
    inner = inner
        .replaceAll(
          '`<div class="code-block relative mt-6 first:mt-0 group/code">',
          '<div class="code-block relative mt-6 first:mt-0 group/code">',
        )
        .replaceAll('</code></pre></div>`', '</code></pre></div>');

    return '$pre$inner$post';
  }

  String _removeAllLastLineBreaks(String inner) {
    var newInner = inner;
    while (newInner.endsWith('\n')) {
      newInner = newInner.substring(0, newInner.length - 1);
    }
    return newInner;
  }

  // Inline level element.
  String _convertThToMd(Element element, int level) {
    const pre = '';
    final inner = _htmlToMarkdown(element, level + 1);
    const post = '|';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertTdToMd(Element element, int level) {
    const pre = '';
    final inner = _htmlToMarkdown(element, level + 1);
    const post = '|';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertAnchorToMd(Element element, int level) {
    const pre = '[';
    final inner = _htmlToMarkdown(element, level + 1);
    final post = '](${element.attributes['href'] ?? '#'})${level == 0 ? '\n\n' : ''}';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertSpanToMd(Element element, int level) {
    const pre = '';
    final inner = _htmlToMarkdown(element, level + 1);
    final post = level == 0 ? '\n\n' : '';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertStrongToMd(Element element, int level) {
    const pre = '**';
    final inner = _htmlToMarkdown(element, level + 1);
    final post = '**${level == 0 ? '\n\n' : ''}';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertEmToMd(Element element, int level) {
    const pre = '*';
    final inner = _htmlToMarkdown(element, level + 1);
    final post = '*${level == 0 ? '\n\n' : ''}';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertImgToMd(Element element, int level) {
    const pre = '![';
    final inner = element.attributes['alt'] ?? '';
    final post = '](${element.attributes['src'] ?? '#'})${level == 0 ? '\n\n' : ''}';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertCodeToMd(Element element, int level) {
    final insidePre = _context.containsKey('pre');
    final pre = insidePre ? '' : '`';
    _context['code'] = true;
    final inner = _htmlToMarkdown(element, level + 1);
    _context.remove('code');
    final post = '${insidePre ? '' : '`'}${level == 0 ? '\n\n' : ''}';

    return '$pre$inner$post';
  }
}
