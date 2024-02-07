import 'dart:io';
import 'package:path/path.dart' as p;

///
extension DirectoryHelper on Directory {
  /// Copy the whole directory content.
  /// Ex.: /temp/assets -> /temp/assets :: this -> destination.
  Future<void> copyContent(Directory destination) async {
    for (final entity in listSync(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(path.length + 1);
        final destinationFile = File(p.join(destination.path, relativePath));
        await destinationFile.parent.create(recursive: true);
        await entity.copy(destinationFile.path);
      }
    }
  }
}
