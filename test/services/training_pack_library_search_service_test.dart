import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_library_search_service.dart';
import 'package:poker_analyzer/services/training_pack_index_service.dart';
import 'package:poker_analyzer/generated/pack_library.g.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  late TrainingPackLibrarySearchService service;

  setUp(() {
    packLibrary['starter_pushfold_10bb'] = [];
    service = TrainingPackLibrarySearchService(
      indexService: TrainingPackIndexService.instance,
    );
  });

  tearDown(() => packLibrary.clear());

  test('returns all packs when no filters provided', () {
    final result = service.search();
    expect(result.map((m) => m.id), contains('starter_pushfold_10bb'));
  });

  test('filters by includeTags', () {
    final match = service.search(includeTags: ['starter', 'pushfold']);
    expect(match.map((m) => m.id), ['starter_pushfold_10bb']);

    final noMatch = service.search(includeTags: ['starter', 'missing']);
    expect(noMatch, isEmpty);
  });

  test('filters by skill level and training type', () {
    final match = service.search(
      skillLevel: 'beginner',
      trainingType: TrainingType.pushFold,
    );
    expect(match.map((m) => m.id), ['starter_pushfold_10bb']);

    expect(service.search(skillLevel: 'advanced'), isEmpty);
    expect(service.search(trainingType: TrainingType.postflop), isEmpty);
  });
}
