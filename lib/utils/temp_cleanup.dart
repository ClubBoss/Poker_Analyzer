import 'dart:io';

/// Deletes temp directories under [Directory.systemTemp] whose names start
/// with [prefix] and whose last-modified time is older than [maxAge].
Future<void> cleanupOldTempDirs({
  required String prefix,
  Duration maxAge = const Duration(days: 3),
  DateTime? now,
}) async {
  final tmp = Directory.systemTemp;
  final clock = now ?? DateTime.now();
  try {
    await for (final ent in tmp.list(followLinks: false)) {
      if (ent is! Directory) continue;
      final base = ent.uri.pathSegments.isNotEmpty
          ? ent.uri.pathSegments.last
          : ent.path.split(Platform.pathSeparator).last;
      if (!base.startsWith(prefix)) continue;
      DateTime? mtime;
      try {
        final stat = await ent.stat();
        mtime = stat.modified;
      } catch (_) {}
      if (mtime != null && clock.difference(mtime) > maxAge) {
        try {
          await ent.delete(recursive: true);
        } catch (_) {}
      }
    }
  } catch (_) {}
}
