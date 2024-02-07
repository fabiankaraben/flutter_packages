import 'package:html/dom.dart';

///
extension HtmlNodeHelper on Node {
  ///
  bool get isElementNode => nodeType == 1;

  ///
  bool get isAttrNode => nodeType == 2;

  ///
  bool get isTextNode => nodeType == 3;

  /// Trimed text.
  String get trimedText => text!.trim();
}
