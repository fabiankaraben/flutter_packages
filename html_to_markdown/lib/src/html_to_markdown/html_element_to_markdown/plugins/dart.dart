/// Plugin class for Dart website specific behaviors on HtmlToMd class.
class HtmlToMdDart {
  ///
  String endingReplacements(String md) {
    return md.replaceAll('dart```', '```dart').replaceAll('```\ndart', '```dart');
  }
}
