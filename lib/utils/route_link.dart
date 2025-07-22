class RouteLink {
  final String pathId;
  final String? stageId;

  const RouteLink({required this.pathId, this.stageId});

  /// Parses [uri] and returns a [RouteLink] if it matches `/learn`.
  /// Expected format: `/learn?path=VALUE&stage=VALUE`.
  static RouteLink? tryParse(Uri uri) {
    if (uri.path != '/learn') return null;
    final path = uri.queryParameters['path'];
    if (path == null || path.isEmpty) return null;
    final stage = uri.queryParameters['stage'];
    return RouteLink(pathId: path, stageId: stage);
  }
}
