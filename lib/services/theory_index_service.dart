import 'theory_library_index.dart';
import '../models/theory_snippet.dart';

class TheoryIndexService {
  final TheoryLibraryIndex _library;
  TheoryIndexService({TheoryLibraryIndex? library})
    : _library = library ?? TheoryLibraryIndex();

  /// Returns all snippets matching [tag].
  Future<List<TheorySnippet>> snippetsForTag(String tag) async {
    final resources = await _library.all();
    final result = <TheorySnippet>[];
    for (final res in resources) {
      if (res.tags.contains(tag)) {
        result.add(
          TheorySnippet(
            id: res.id,
            title: res.title,
            bullets: ['Key concept: ${res.title}'],
            uri: res.uri,
          ),
        );
      }
    }
    return result;
  }

  /// Retained for backwards compatibility; returns the first matching snippet.
  Future<TheorySnippet?> matchSnippet(
    List<String> tags, {
    Set<String>? exclude,
  }) async {
    if (tags.isEmpty) return null;
    final resources = await _library.all();
    for (final res in resources) {
      if (exclude?.contains(res.id) ?? false) continue;
      if (res.tags.any(tags.contains)) {
        return TheorySnippet(
          id: res.id,
          title: res.title,
          bullets: ['Key concept: ${res.title}'],
          uri: res.uri,
        );
      }
    }
    return null;
  }
}
