import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import '../models/sub_stage_model.dart';
import '../models/pack_library.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'learning_path_stage_library.dart';

/// Creates learning path stages from promoted theory packs.
class LearningPathAutoSeeder {
  LearningPathAutoSeeder();

  /// Generates stages from [PackLibrary.main] and stores them in
  /// [LearningPathStageLibrary].
  Future<void> seed() async {
    final groups = <String, List<TrainingPackTemplateV2>>{};
    for (final pack in PackLibrary.main.packs) {
      final source = pack.meta['source']?.toString();
      if (source != 'theory_promoted') continue;
      final category = pack.meta['category']?.toString().toLowerCase();
      if (category == null || category.isEmpty) continue;
      groups.putIfAbsent(category, () => []).add(pack);
    }

    final library = LearningPathStageLibrary.instance;
    library.clear();

    const mapping = {
      'starter': 'theory_intro',
      'core': 'theory_core',
      'advanced': 'theory_advanced',
    };
    const titles = {
      'starter': 'Введение в теорию',
      'core': 'Базовая теория',
      'advanced': 'Продвинутая теория',
    };

    var order = 0;
    for (final entry in mapping.entries) {
      final packs = groups[entry.key];
      if (packs == null || packs.isEmpty) continue;
      final mainPack = packs.first;
      final subStages = <SubStageModel>[];
      for (final p in packs.skip(1)) {
        subStages.add(
          SubStageModel(
            id: p.id,
            packId: p.id,
            title: p.name,
            description: p.description,
          ),
        );
      }

      final stage = LearningPathStageModel(
        id: entry.value,
        title: titles[entry.key]!,
        description: '',
        packId: mainPack.id,
        requiredAccuracy: 0,
        minHands: 0,
        type: StageType.theory,
        subStages: subStages,
        order: order++,
      );
      library.add(stage);
    }
  }
}
