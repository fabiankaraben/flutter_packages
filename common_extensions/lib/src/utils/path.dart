/// Clean a source path leaving only the relative part.
String leftCleanSourcePath(String pagePath, String fullPath) {
  // Get just the relative part for source paths.
  if (pagePath.startsWith(fullPath)) return pagePath.substring(fullPath.length);

  return pagePath;
}
