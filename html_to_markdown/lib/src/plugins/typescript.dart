import 'package:html/dom.dart';

/// Plugin class for TypeScript website specific behaviors on HtmlToMd class.
class HtmlToMdTypeScript {
  ///
  void addExtraConvertions(
    Element element,
    int level,
    StringBuffer md,
    String Function(Element, int) htmlToMarkdown,
    Map<String, dynamic> context,
  ) {
    if (element.localName == 'data-lsp') {
      md.write(_convertDataLspToMd(element, level, htmlToMarkdown, context));
    } else if (element.localName == 'data-err') {
      md.write(_convertDataErrToMd(element, level, htmlToMarkdown, context));
    }
  }

  // Inline level element.
  String _convertDataLspToMd(
    Element element,
    int level,
    String Function(Element, int) htmlToMarkdown,
    Map<String, dynamic> context,
  ) {
    const pre = '';
    final inner = htmlToMarkdown(element, level + 1);
    final post = level == 0 ? '\n\n' : '';

    return '$pre$inner$post';
  }

  // Inline level element.
  String _convertDataErrToMd(
    Element element,
    int level,
    String Function(Element, int) htmlToMarkdown,
    Map<String, dynamic> context,
  ) {
    const pre = '';
    final inner = htmlToMarkdown(element, level + 1);
    final post = level == 0 ? '\n\n' : '';

    return '$pre$inner$post';
  }

  ///
  static String convertPreToMd(
    Element element,
    int level,
    String Function(Element, int) htmlToMarkdown,
    Map<String, dynamic> context,
  ) {
    final insideTr = context.containsKey('tr');
    final insideCode = context.containsKey('code');
    final startEndChars = insideCode ? '``' : '```';

    final langElement = element.querySelector('div.language-id');
    if (langElement != null) langElement.remove();

    final errorElement = element.querySelector('span.error');
    errorElement?.querySelector('span.code')?.remove();
    if (errorElement != null) errorElement.remove();
    final errorMsg = errorElement != null
        ? '\n\n${startEndChars}text {filename="Generated error"}\n${htmlToMarkdown(errorElement, 1000)}\n$startEndChars'
        : '';
    element.querySelector('span.error-behind')?.remove();

    final pre = '$startEndChars${langElement?.text ?? ''}\n';
    context['pre'] = true;
    var inner = htmlToMarkdown(element, level + 1);
    context.remove('pre');

    // Extract 'Try' anchor.
    var tryAnchor = '';
    if (inner.contains('[Try](')) {
      final initIdx = inner.indexOf('[Try](');
      tryAnchor = '${inner.substring(initIdx)}\n'.replaceFirst('Try', 'Try this code');
      inner = inner.substring(0, initIdx);
    }

    // Remove the '\n\n' from the las 'div' line.
    if (inner.endsWith('\n\n')) inner = inner.substring(0, inner.length - 2);

    // Remove the '\n' from the las 'div' line.
    if (inner.endsWith('\n')) inner = inner.substring(0, inner.length - 1);

    final post = level == 0
        ? '\n$startEndChars$errorMsg\n\n'
        : (insideCode ? '\n$startEndChars$errorMsg' : '\n$startEndChars$errorMsg\n');

    if (insideTr) {
      return '<div class="code-block relative mt-6 first:mt-0 group/code"><pre><code>'
          '$inner'
          '</code></pre></div>';
    }

    return '$tryAnchor$pre$inner$post';
  }
}
