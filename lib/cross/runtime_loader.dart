// Runtime loader for training_v1 bundles.
// ASCII-only, pure Dart, zero deps.

import 'dart:convert';
import 'dart:io';

enum FeedKind { l2_session, l3_session, l4_session }

class LoadedSession {
  final FeedKind kind;
  final String path;
  final int count;
  const LoadedSession({
    required this.kind,
    required this.path,
    required this.count,
  });
}

class LoadedBundle {
  final String version;
  final List<LoadedSession> sessions;
  const LoadedBundle({required this.version, required this.sessions});
}

LoadedBundle loadTrainingBundle({
  required File feedJson,
  required Directory root,
}) {
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('expected map');
  }

  List _asList(dynamic v) => v is List ? v : const [];

  String _asString(dynamic v) {
    if (v is String) return v;
    throw const FormatException('expected string');
  }

  Map<String, dynamic> _readFile(String path) {
    final txt = File(path).readAsStringSync();
    final data = jsonDecode(txt);
    return _asMap(data);
  }

  final feedMap = _readFile(feedJson.path);
  final version = _asString(feedMap['version'] ?? 'v1');
  final items = _asList(feedMap['items']);
  final loaded = <LoadedSession>[];

  for (final raw in items) {
    final item = _asMap(raw);
    final kindStr = _asString(item['kind']);
    final fileStr = _asString(item['file']);

    late FeedKind kind;
    switch (kindStr) {
      case 'l2_session':
        kind = FeedKind.l2_session;
        break;
      case 'l3_session':
        kind = FeedKind.l3_session;
        break;
      case 'l4_session':
        kind = FeedKind.l4_session;
        break;
      default:
        throw const FormatException('unknown kind');
    }

    var path = fileStr;
    if (!File(path).isAbsolute) {
      path = root.uri.resolve(fileStr).toFilePath();
    }

    final sessionMap = _readFile(path);
    int count;
    if (kind == FeedKind.l2_session) {
      count = _asList(sessionMap['items']).length;
    } else if (kind == FeedKind.l3_session) {
      final inline = _asList(sessionMap['inlineItems']);
      count = inline.isNotEmpty
          ? inline.length
          : _asList(sessionMap['items']).length;
    } else {
      count = _asList(sessionMap['items']).length;
    }

    loaded.add(LoadedSession(kind: kind, path: path, count: count));
  }

  return LoadedBundle(version: version, sessions: loaded);
}

int totalItems(LoadedBundle b) =>
    b.sessions.fold(0, (prev, s) => prev + s.count);
