import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/training_pack_template_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/services/smart_recap_booster_linker.dart';
import 'package:poker_analyzer/services/training_pack_template_storage_service.dart';
import 'package:poker_analyzer/services/pack_library_loader_service.dart';

class _FakeStorage extends TrainingPackTemplateStorageService {
  final List<TrainingPackTemplateModel> models;
  final Map<String, TrainingPackTemplateV2> packs;
  _FakeStorage(this.models, this.packs);

  @override
  Future<void> load() async {}

  @override
  List<TrainingPackTemplateModel> get templates => models;

  @override
  Future<TrainingPackTemplateV2> loadBuiltinTemplate(String id) async {
    return packs[id]!;
  }
}

class _FakeLibrary implements PackLibraryLoaderService {
  final List<TrainingPackTemplateV2> items;
  const _FakeLibrary(this.items);

  @override
  Future<List<TrainingPackTemplateV2>> loadLibrary() async => items;

  @override
  List<TrainingPackTemplateV2> get library => List.unmodifiable(items);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pack1 = TrainingPackTemplateV2(
    id: 'p1',
    name: 'P1',
    trainingType: TrainingType.pushFold,
    tags: const ['cbet'],
    spots: const [],
    spotCount: 8,
    gameType: GameType.tournament,
  );
  final pack2 = TrainingPackTemplateV2(
    id: 'p2',
    name: 'P2',
    trainingType: TrainingType.pushFold,
    tags: const ['call'],
    spots: const [],
    spotCount: 12,
    gameType: GameType.tournament,
  );

  final storage = _FakeStorage(
    [
      const TrainingPackTemplateModel(
        id: 'p1',
        name: 'P1',
        description: '',
        category: 'A',
        filters: {
          'tags': ['cbet']
        },
      ),
      const TrainingPackTemplateModel(
        id: 'p2',
        name: 'P2',
        description: '',
        category: 'B',
        filters: {
          'tags': ['call']
        },
      ),
    ],
    {
      'p1': pack1,
      'p2': pack2,
    },
  );

  final linker = SmartRecapBoosterLinker(
    storage: storage,
    library: const _FakeLibrary([pack1, pack2]),
  );

  test('returns matching small booster packs', () async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'L1',
      content: '',
      tags: ['cbet'],
    );
    final result = await linker.getBoostersForLesson(lesson);
    expect(result.length, 1);
    expect(result.first.id, 'p1');
  });

  test('returns empty when no tags match', () async {
    const lesson = TheoryMiniLessonNode(
      id: 'l2',
      title: 'L2',
      content: '',
      tags: ['icm'],
    );
    final result = await linker.getBoostersForLesson(lesson);
    expect(result, isEmpty);
  });
}
