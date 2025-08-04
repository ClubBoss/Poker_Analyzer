import 'package:test/test.dart';
import 'package:poker_analyzer/generated/pack_library.g.dart';
import 'package:poker_analyzer/services/training_pack_library_search_suggestions_service.dart';
import 'package:poker_analyzer/services/training_pack_index_service.dart';

void main() {
  late TrainingPackLibrarySearchSuggestionsService service;

  setUp(() {
    packLibrary.addAll({
      'starter_pushfold_10bb': [],
      'starter_postflop_basics': [],
      'advanced_pushfold_15bb': [],
    });
    service = TrainingPackLibrarySearchSuggestionsService(
      indexService: TrainingPackIndexService.instance,
    );
  });

  tearDown(() => packLibrary.clear());

  test('returns most popular tags', () {
    final tags = service.getSuggestedTags(limit: 2);
    expect(tags.length, 2);
    expect(tags, containsAll(['starter', 'pushfold']));
  });

  test('returns starter packs for onboarding', () {
    final packs = service.getSuggestedStarterPacks();
    expect(packs.map((m) => m.id), [
      'starter_postflop_basics',
      'starter_pushfold_10bb',
    ]);
  });
}
