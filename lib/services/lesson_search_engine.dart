import 'dart:math';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Provides fuzzy search over theory mini lessons.
class LessonSearchEngine {
  LessonSearchEngine({List<TheoryMiniLessonNode>? library})
    : _library = library;

  final List<TheoryMiniLessonNode>? _library;

  List<TheoryMiniLessonNode> search(String query, {int limit = 10}) {
    final lessons = _library ?? MiniLessonLibraryService.instance.all;
    if (lessons.isEmpty) return const [];
    final q = _normalize(query);
    if (q.isEmpty) return lessons.take(limit).toList();

    final scored = <_ScoredLesson>[];
    for (final lesson in lessons) {
      final title = _normalize(lesson.resolvedTitle);
      final content = _normalize(lesson.resolvedContent);
      final tagScores = [
        for (final t in lesson.tags) _similarity(q, _normalize(t)),
      ];
      final tagScore = tagScores.isEmpty ? 0.0 : tagScores.reduce(max);
      final score =
          _similarity(q, title) * 0.6 +
          tagScore * 0.3 +
          _similarity(q, content) * 0.1;
      if (score > 0) scored.add(_ScoredLesson(lesson, score));
    }
    if (scored.isEmpty) return const [];
    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final s in scored.take(limit)) s.lesson];
  }

  double _similarity(String a, String b) {
    final ta = _trigrams(a);
    final tb = _trigrams(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length.toDouble();
    final union = ta.union(tb).length.toDouble();
    return union == 0 ? 0 : inter / union;
  }

  Set<String> _trigrams(String s) {
    final clean = _normalize(s).replaceAll(RegExp(r'[^a-z0-9]'), '');
    final set = <String>{};
    if (clean.length <= 3) {
      if (clean.isNotEmpty) set.add(clean);
      return set;
    }
    for (var i = 0; i <= clean.length - 3; i++) {
      set.add(clean.substring(i, i + 3));
    }
    return set;
  }

  String _normalize(String s) => _removeDiacritics(s).toLowerCase();

  String _removeDiacritics(String str) {
    const map = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
      'ý': 'y',
      'ÿ': 'y',
      'Á': 'a',
      'À': 'a',
      'Â': 'a',
      'Ã': 'a',
      'Ä': 'a',
      'Å': 'a',
      'É': 'e',
      'È': 'e',
      'Ê': 'e',
      'Ë': 'e',
      'Í': 'i',
      'Ì': 'i',
      'Î': 'i',
      'Ï': 'i',
      'Ó': 'o',
      'Ò': 'o',
      'Ô': 'o',
      'Õ': 'o',
      'Ö': 'o',
      'Ú': 'u',
      'Ù': 'u',
      'Û': 'u',
      'Ü': 'u',
      'Ç': 'c',
      'Ñ': 'n',
      'Ý': 'y',
    };
    final buffer = StringBuffer();
    for (final code in str.runes) {
      final ch = String.fromCharCode(code);
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString();
  }
}

class _ScoredLesson {
  final TheoryMiniLessonNode lesson;
  final double score;
  _ScoredLesson(this.lesson, this.score);
}
