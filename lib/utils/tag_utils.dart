/// Утилиты работы с тегами (без Flutter).
library tag_utils;

/// Удаляет дубликаты, сохраняя порядок первых вхождений.
/// По умолчанию сравнение без учета регистра, но возвращаются исходные строки.
List<String> dedupTags(Iterable<String> tags, {bool caseInsensitive = true}) {
  final seen = <String>{};
  final result = <String>[];
  for (final t in tags) {
    final key = caseInsensitive ? t.toLowerCase() : t;
    if (seen.add(key)) result.add(t);
  }
  return result;
}
