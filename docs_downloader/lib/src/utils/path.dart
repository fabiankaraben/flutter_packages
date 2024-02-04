/// Remove web.archive.org part. Ex.:
///   from: https://web.archive.org/web/20231118115033/https://www.typescriptlang.org/docs/
///   to: https://www.typescriptlang.org/docs/
/// Or:
///   from: /web/20231118115033/https://www.typescriptlang.org/docs/
///   to: https://www.typescriptlang.org/docs/
String getPathWithoutArchiveOrg(String path) {
  if (!path.contains('/web/20')) return path;

  final idxOfHttp = path.indexOf('/http') + 1;
  if (idxOfHttp == -1) return path;
  return path.substring(idxOfHttp);
}
