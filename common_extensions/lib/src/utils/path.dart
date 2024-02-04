import 'dart:io';

/// Clean a source path leaving only the relative part.
String leftCleanSourcePath(String pagePath, String fullPath) {
  // Get just the relative part for source paths.
  if (pagePath.startsWith(fullPath)) return pagePath.substring(fullPath.length);

  return pagePath;
}

/// Remove the local part of a downloaded HTML file, leaving just the relative part.
String leftCleanLocalHtmlFilePath(String pagePath, Directory htmlDownloadsDir) {
  var path = pagePath;

  // Get just the relative part for downloaded ('html' direcotory) paths.
  if (path.startsWith(htmlDownloadsDir.path)) {
    path = path.substring(htmlDownloadsDir.path.length);
  }

  return path;
}

/// Remove the local part of a downloaded HTML file, leaving just the relative part.
String cleanLocalHtmlFilePath(String pagePath, Directory htmlDownloadsDir) {
  var path = pagePath;

  path = leftCleanLocalHtmlFilePath(path, htmlDownloadsDir);

  if (path.endsWith('.html')) path = path.substring(0, path.length - '.html'.length);

  return path;
}
