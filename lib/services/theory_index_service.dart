import 'theory_library_index.dart';
import '../models/theory_snippet.dart';

class TheoryIndexService {
  final TheoryLibraryIndex _library;
  TheoryIndexService({TheoryLibraryIndex? library})
      : _library = library ?? TheoryLibraryIndex();

  Future<TheorySnippet?> matchSnippet(List<String> tags,
      {Set<String>? exclude}) async {
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
