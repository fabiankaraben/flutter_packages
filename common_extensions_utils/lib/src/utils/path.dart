import 'dart:io';

/// Clean a source path leaving only the relative part.
String leftCleanSourcePath(String pagePath, String absolutePathPart) {
  // Get just the relative part for source paths.
  if (pagePath.startsWith(absolutePathPart)) return pagePath.substring(absolutePathPart.length);

  return pagePath;
}

/// Remove query parameters.
String rightCleanSourcePath(String pagePath) {
  return pagePath.split('#').first;
}

/// Remove authority (protocol + host) and query parameters.
String leftRightCleanSourcePath(String pagePath, String absolutePathPart) {
  return leftCleanSourcePath(rightCleanSourcePath(pagePath), absolutePathPart);
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
