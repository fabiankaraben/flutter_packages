/// Plugin class for Dart website specific behaviors on HtmlToMd class.
class HtmlToMdDart {
  ///
  String endingReplacements(String md) {
    return md
        .replaceAll('dart```', '```dart')
        .replaceAll('```\ndart', '```dart')
        .replaceAll('bad```dart', '```dart {filename="Bad code"}')
        .replaceAll(
          '✗ static analysis: failure```dart',
          '```dart {filename="✗ static analysis: failure"}',
        );
  }
}
