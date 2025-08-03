import 'package:meta/meta.dart';

@immutable
class RouteLink {
  final String pathId;
  final String? stageId;

  const RouteLink({required this.pathId, this.stageId});

  /// Parses [uri] and returns a [RouteLink] if it matches one of the supported
  /// formats:
  ///
  /// - `/learn?path=VALUE&stage=VALUE`
  /// - `/path/{pathId}/stage/{stageId}`
  static RouteLink? tryParse(Uri uri) {
    // Legacy query parameter based format.
    if (uri.path == '/learn') {
      final path = uri.queryParameters['path'];
      if (path == null || path.isEmpty) return null;
      final stage = uri.queryParameters['stage'];
      return RouteLink(pathId: path, stageId: stage);
    }

    // New deep link format with path segments.
    final segments = uri.pathSegments;
    if (segments.length >= 4 &&
        segments[0] == 'path' &&
        segments[2] == 'stage') {
      final pathId = segments[1];
      final stageId = segments[3];
      if (pathId.isEmpty) return null;
      return RouteLink(pathId: pathId, stageId: stageId);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteLink && other.pathId == pathId && other.stageId == stageId;

  @override
  int get hashCode => Object.hash(pathId, stageId);
}
