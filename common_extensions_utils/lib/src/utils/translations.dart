///
String removeAllContentPaths(String content) {
  final sb = StringBuffer();
  var preTextStart = 0;
  var pathStart = content.indexOf('](');
  while (pathStart != -1) {
    pathStart += 2; // Avoiding the '](' part.
    final pathEnd = content.indexOf(')', pathStart);

    if (content[pathStart - 3] == '↗') {
      var offset = 3;
      if (content[pathStart - 4] == ' ') offset++;

      sb.writeAll([
        content.substring(preTextStart, pathStart - offset),
        '](',
      ]);
    } else {
      sb.write(content.substring(preTextStart, pathStart));
    }

    preTextStart = pathEnd;
    pathStart = content.indexOf('](', pathEnd);
  }
  sb.write(content.substring(preTextStart, content.length));

  return sb.toString();
}

///
String addAllContentPaths(String sourceContent, String translatedContent) {
  final pathsData = _getPathsData(sourceContent);

  final sb = StringBuffer();
  var preTextStart = 0;
  var pathStart = translatedContent.indexOf('](');
  var i = 0;
  while (pathStart != -1) {
    final pathEnd = translatedContent.indexOf(')', pathStart);

    final (path, isExternal) = pathsData[i];

    sb.writeAll([
      translatedContent.substring(preTextStart, pathStart),
      if (isExternal) ' ↗',
      '](',
      path,
    ]);

    preTextStart = pathEnd;
    pathStart = translatedContent.indexOf('](', pathEnd);
    i++;
  }
  sb.write(translatedContent.substring(preTextStart, translatedContent.length));

  return sb.toString();
}

List<(String, bool)> _getPathsData(String sourceContent) {
  final res = <(String, bool)>[];

  var pathStart = sourceContent.indexOf('](');
  while (pathStart != -1) {
    pathStart += 2; // Avoiding the '](' part.
    final pathEnd = sourceContent.indexOf(')', pathStart);
    final path = sourceContent.substring(pathStart, pathEnd);
    final isExternal = sourceContent[pathStart - 3] == '↗';

    res.add((path, isExternal));

    pathStart = sourceContent.indexOf('](', pathEnd);
  }

  return res;
}
