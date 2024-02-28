/// Remove web.archive.org part. Ex.:
///   from: https://web.archive.org/web/20231118115033/https://www.typescriptlang.org/docs/
///   to: https://www.typescriptlang.org/docs/
/// Or:
///   from: /web/20231118115033/https://www.typescriptlang.org/docs/
///   to: https://www.typescriptlang.org/docs/
String getPathWithoutArchiveOrg(String path) {
  if (!path.contains('/web/20')) return path;

  // Note: '/https://' is mandatory because URL like
  // https://web.archive.org/web/20231018224739/https://nextjs.org/docs/app/api-reference/next-config-js/httpAgentOptions
  // can generate an bug with just '/http'.

  var pathVal = path;
  var idxOfHttp = path.indexOf('/https://');
  // Note: some links has the archive.org two times, so it's using a while loop.
  while (idxOfHttp != -1) {
    pathVal = pathVal.substring(idxOfHttp + 1);
    idxOfHttp = pathVal.indexOf('/https://');
  }
  return pathVal;
}
