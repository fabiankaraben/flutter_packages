/// Remove web.archive.org part. Ex.:
///   from: https://web.archive.org/web/20231118115033/https://www.typescriptlang.org/docs/
///   to: https://www.typescriptlang.org/docs/
/// Or:
///   from: /web/20231118115033/https://www.typescriptlang.org/docs/
///   to: https://www.typescriptlang.org/docs/
String getPathWithoutArchiveOrg(String path) {
  if (!path.contains('/web/20')) return path;

  var pathVal = path;
  var idxOfHttp = path.indexOf('/http');
  // Note: some links has the archive.org two times, so it's using a while loop.
  while (idxOfHttp != -1) {
    pathVal = pathVal.substring(idxOfHttp + 1);
    idxOfHttp = pathVal.indexOf('/http');
  }
  return pathVal;
}
