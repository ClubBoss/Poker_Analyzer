import '../models/theory_tag_heatmap_stats.dart';
import 'mini_lesson_library_service.dart';

/// Computes tag-level heatmap metrics for theory mini lessons.
class TheoryLessonTagHeatmapService {
  final MiniLessonLibraryService library;

  TheoryLessonTagHeatmapService({MiniLessonLibraryService? library})
    : library = library ?? MiniLessonLibraryService.instance;

  /// Returns statistics for each tag found in [library].
  Future<Map<String, TheoryTagStats>> computeHeatmap() async {
    await library.loadAll();
    final lessons = library.all;
    final byId = {for (final l in lessons) l.id: l};
    final incoming = <String, int>{for (final l in lessons) l.id: 0};

    for (final l in lessons) {
      for (final next in l.nextIds) {
        if (byId.containsKey(next)) {
          incoming[next] = (incoming[next] ?? 0) + 1;
        }
      }
    }

    final Map<String, _Builder> map = {};
    for (final l in lessons) {
      final inc = incoming[l.id] ?? 0;
      final out = l.nextIds.where((id) => byId.containsKey(id)).length;
      for (final tag in l.tags) {
        final trimmed = tag.trim();
        if (trimmed.isEmpty) continue;
        final b = map.putIfAbsent(trimmed, () => _Builder());
        b.count++;
        b.incoming += inc;
        b.outgoing += out;
      }
    }

    final result = <String, TheoryTagStats>{};
    for (final entry in map.entries) {
      result[entry.key] = TheoryTagStats(
        tag: entry.key,
        count: entry.value.count,
        incomingLinks: entry.value.incoming,
        outgoingLinks: entry.value.outgoing,
      );
    }
    return result;
  }

  /// Returns tags with no incoming or outgoing links.
  List<String> deadTags(Map<String, TheoryTagStats> stats) {
    final result = <String>[];
    for (final s in stats.values) {
      if (s.incomingLinks == 0 && s.outgoingLinks == 0) {
        result.add(s.tag);
      }
    }
    return result;
  }
}

class _Builder {
  int count = 0;
  int incoming = 0;
  int outgoing = 0;
}
