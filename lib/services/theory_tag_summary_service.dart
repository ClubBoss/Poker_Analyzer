import '../models/theory_tag_stats.dart';
import 'mini_lesson_library_service.dart';

/// Summarizes theory mini lesson coverage by tag.
class TheoryTagSummaryService {
  final MiniLessonLibraryService library;

  TheoryTagSummaryService({MiniLessonLibraryService? library})
      : library = library ?? MiniLessonLibraryService.instance;

  /// Returns statistics for each tag found in [library].
  Future<Map<String, TheoryTagStats>> computeSummary() async {
    await library.loadAll();
    final Map<String, _TagBuilder> map = {};
    for (final lesson in library.all) {
      final words = _countWords(lesson.content);
      final examples = _countExamples(lesson.content);
      final connected = lesson.nextIds.isNotEmpty;
      for (final tag in lesson.tags) {
        final trimmed = tag.trim();
        if (trimmed.isEmpty) continue;
        final data = map.putIfAbsent(trimmed, () => _TagBuilder());
        data.lessonCount++;
        data.exampleCount += examples;
        data.totalLength += words;
        data.connected |= connected;
      }
    }
    final result = <String, TheoryTagStats>{};
    for (final entry in map.entries) {
      final builder = entry.value;
      final avgLength = builder.lessonCount > 0
          ? builder.totalLength / builder.lessonCount
          : 0.0;
      result[entry.key] = TheoryTagStats(
        tag: entry.key,
        lessonCount: builder.lessonCount,
        exampleCount: builder.exampleCount,
        avgLength: avgLength,
        connectedToPath: builder.connected,
      );
    }
    return result;
  }

  /// Builds a markdown table from [stats]. Useful for diagnostics.
  String buildMarkdownReport(Map<String, TheoryTagStats> stats) {
    final buffer = StringBuffer(
      '| Tag | Lessons | Examples | Avg Length | Connected |\n',
    );
    buffer.writeln('| --- | --- | --- | --- | --- |');
    final entries = stats.values.toList()
      ..sort((a, b) => a.tag.compareTo(b.tag));
    for (final s in entries) {
      buffer.writeln(
        '| ${s.tag} | ${s.lessonCount} | ${s.exampleCount} | '
        '${s.avgLength.toStringAsFixed(1)} | ${s.connectedToPath} |',
      );
    }
    return buffer.toString();
  }

  int _countWords(String text) => RegExp(r'\w+').allMatches(text).length;

  int _countExamples(String text) {
    final reg = RegExp(
      r'^(?:Example|Пример|Например)[:\-]',
      caseSensitive: false,
      multiLine: true,
    );
    return reg.allMatches(text).length;
  }
}

class _TagBuilder {
  int lessonCount = 0;
  int exampleCount = 0;
  int totalLength = 0;
  bool connected = false;
}
