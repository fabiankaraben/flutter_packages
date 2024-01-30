import 'package:mime/mime.dart';

///
extension UriExtension on Uri {
  /// Path without URL encode.
  String get filePath => '/${pathSegments.join('/')}';

  /// filePath but removing the ending slash.
  String get filePathWithoutSlash => filePath != '/' && filePath.endsWith('/')
      ? filePath.substring(0, filePath.length - 1)
      : filePath;

  /// Returns true if the path ends with a valid filename.
  bool get hasFilename =>
      pathSegments.isNotEmpty &&
      pathSegments.last.contains('.') &&
      (pathSegments.last.endsWith('.map') || lookupMimeType(pathSegments.last) != null);

  /// Return the filename if the path has a valid filename.
  String? get filename => hasFilename ? pathSegments.last : null;

  /// Return the filename extension if the path has a valid filename.
  String? get filenameExtension => hasFilename ? extensionFromMime(filename!) : null;
}
