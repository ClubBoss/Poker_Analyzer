import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/pack_library.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/learning_path_auto_seeder.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates stages from promoted packs', () async {
    PackLibrary.main.clear();

    final p1 = TrainingPackTemplateV2(
      id: 's1',
      name: 'Starter',
      trainingType: TrainingType.pushFold,
      meta: {'source': 'theory_promoted', 'category': 'starter'},
    );
    final p2 = TrainingPackTemplateV2(
      id: 'c1',
      name: 'Core1',
      trainingType: TrainingType.pushFold,
      meta: {'source': 'theory_promoted', 'category': 'core'},
    );
    final p3 = TrainingPackTemplateV2(
      id: 'c2',
      name: 'Core2',
      trainingType: TrainingType.pushFold,
      meta: {'source': 'theory_promoted', 'category': 'core'},
    );
    final p4 = TrainingPackTemplateV2(
      id: 'a1',
      name: 'Adv',
      trainingType: TrainingType.pushFold,
      meta: {'source': 'theory_promoted', 'category': 'advanced'},
    );

    PackLibrary.main.addAll([p1, p2, p3, p4]);

    await const LearningPathAutoSeeder().seed();

    final stages = LearningPathStageLibrary.instance.stages;
    expect(stages, hasLength(3));

    final intro = stages.firstWhere((s) => s.id == 'theory_intro');
    expect(intro.packId, 's1');

    final core = stages.firstWhere((s) => s.id == 'theory_core');
    expect(core.packId, 'c1');
    expect(core.subStages, hasLength(1));
    expect(core.subStages.first.packId, 'c2');

    final adv = stages.firstWhere((s) => s.id == 'theory_advanced');
    expect(adv.packId, 'a1');
  });
}
