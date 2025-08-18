import 'mini_lesson_library_builder.dart';

/// Rewrites raw mini lesson snippets into cleaner lessons.
class AutoTheoryRewriter {
  const AutoTheoryRewriter();

  /// Returns cleaned versions of [raw] entries.
  List<MiniLessonEntry> rewrite(List<MiniLessonEntry> raw) {
    final result = <MiniLessonEntry>[];
    for (final e in raw) {
      final words = _tagWords(e.tag);
      final examples = <String>[];
      final content = _rewriteContent(e.content, words, examples);
      final title = _highlightKeywords(_normalize(e.title), words);
      result.add(
        e.copyWith(title: title, content: content, examples: examples),
      );
    }
    return result;
  }

  String _normalize(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  List<String> _tagWords(String tag) => tag
      .toLowerCase()
      .split(RegExp(r'[\s_:/-]+'))
      .where((w) => w.isNotEmpty)
      .toList();

  String _highlightKeywords(String text, List<String> words) {
    var res = text;
    for (final w in words) {
      final regex = RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false);
      res = res.replaceAllMapped(regex, (m) => '**${m[0]}**');
    }
    return res;
  }

  String _rewriteContent(
    String content,
    List<String> words,
    List<String> examples,
  ) {
    final lines = content.split(RegExp('[\n\r]+'));
    final kept = <String>[];
    final exampleReg = RegExp(
      r'^(?:Example|Пример|Например)[:\-]\s*(.+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = exampleReg.firstMatch(line.trim());
      if (match != null) {
        final ex = _highlightKeywords(_normalize(match.group(1)!), words);
        examples.add(ex);
      } else {
        kept.add(line);
      }
    }
    final text = kept.join(' ');
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    final bullets = <String>[];
    for (final s in sentences) {
      final trimmed = _normalize(s);
      if (trimmed.isEmpty) continue;
      final high = _highlightKeywords(trimmed, words);
      bullets.add('- $high');
    }
    return bullets.join('\n');
  }
}
