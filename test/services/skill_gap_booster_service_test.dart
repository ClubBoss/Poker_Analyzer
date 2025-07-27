import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_gap_booster_service.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:collection/collection.dart';

class _FakeLibrary implements PackLibraryService {
  final List<TrainingPackTemplateV2> packs;
  _FakeLibrary(this.packs);
  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async =>
      packs.isNotEmpty ? packs.first : null;
  @override
  Future<TrainingPackTemplateV2?> getById(String id) async =>
      packs.firstWhereOrNull((p) => p.id == id);
  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async =>
      packs.firstWhereOrNull((p) => p.tags.contains(tag));
  @override
  Future<List<String>> findBoosterCandidates(String tag) async => const [];
}

TrainingPackTemplateV2 tpl(String id, List<String> tags, int count) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: tags,
    spots: const [],
    spotCount: count,
    created: DateTime.now(),
    positions: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns packs covering weakest tags sorted by coverage', () async {
    final library = _FakeLibrary([
      tpl('p1', ['push', 'icm'], 5),
      tpl('p2', ['icm'], 4),
      tpl('p3', ['sbvsbb', 'cbet'], 6),
      tpl('p4', ['push', 'sbvsbb'], 9),
      tpl('p5', ['push'], 12),
    ]);
    final service = SkillGapBoosterService(library: library);
    final result = await service.suggestBoosters(
      requiredTags: ['push', 'icm', 'sbvsbb'],
      masteryMap: {'push': 0.3, 'icm': 0.5, 'sbvsbb': 0.2},
      count: 3,
    );
    expect(result.map((p) => p.id).toList(), ['p4', 'p1', 'p3']);
  });

  test('filters packs with many spots', () async {
    final library = _FakeLibrary([
      tpl('p1', ['push'], 12),
      tpl('p2', ['push'], 5),
    ]);
    final service = SkillGapBoosterService(library: library);
    final result = await service.suggestBoosters(
      requiredTags: ['push'],
      masteryMap: {'push': 0.2},
    );
    expect(result.map((p) => p.id).toList(), ['p2']);
  });
}
