///
(String, String) splitFrontMatterAndContent(String fullMd) {
  final startFM = fullMd.indexOf('---');
  final endFM = fullMd.indexOf('---', startFM + 3) + 3;

  final frontMatter = fullMd.substring(startFM, endFM);
  final md = fullMd.substring(endFM).trim();

  return (frontMatter, md);
}

///
String joinFrontMatterAndContent(String frontMatter, String content) {
  return [frontMatter, '', if (content.isNotEmpty) content, if (content.isNotEmpty) ''].join('\n');
}

///
String? getFrontMatterValue(String frontMatter, String key) {
  final lines = frontMatter.split('\n');
  for (final line in lines) {
    final l = line.trim();
    if (l.trim().startsWith('$key:')) {
      return l.substring('$key:'.length + 1).trim();
    }
  }
  return null;
}

///
String editFrontMatter(String frontMatter, Map<String, String> keyValues) {
  final lines = <String>[];
  for (final line in frontMatter.split('\n')) {
    if (line.trim() != '---') lines.add(line.trim());
  }

  for (final key in keyValues.keys) {
    final value = keyValues[key];

    var isFound = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('$key:')) {
        lines[i] = '$key: $value';
        isFound = true;
        break;
      }
    }

    if (!isFound) {
      lines.add('$key: $value');
    }
  }

  return [
    '---',
    ...lines,
    '---',
  ].join('\n');
}
