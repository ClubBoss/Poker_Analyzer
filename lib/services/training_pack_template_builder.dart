import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'tag_mastery_service.dart';

class TrainingPackTemplateBuilder {
  const TrainingPackTemplateBuilder();

  Future<TrainingPackTemplateV2> buildSimplifiedPack(
    List<TrainingPackSpot> mistakes,
    TagMasteryService mastery,
  ) async {
    await TrainingPackLibraryV2.instance.reload();
    final library = TrainingPackLibraryV2.instance.packs;

    final base = mistakes.take(3).toList();
    final spots = <TrainingPackSpot>[...base];
    final weakTags = await mastery.topWeakTags(2);
    for (final m in base) {
      TrainingPackSpot? added;
      for (final tpl in library) {
        for (final s in tpl.spots) {
          if (s.hand.position == m.hand.position && s.street == m.street) {
            final tags = [for (final t in s.tags) t.toLowerCase()];
            final hasWeak = weakTags.any((t) => tags.contains(t));
            if (hasWeak) {
              added = TrainingPackSpot.fromJson(s.toJson());
              break;
            }
            added ??= TrainingPackSpot.fromJson(s.toJson());
          }
        }
        if (added != null) break;
      }
      if (added != null && !spots.any((e) => e.id == added.id)) {
        spots.add(added);
      }
      if (spots.length >= base.length + 3) break;
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final tagLabel = weakTags.isNotEmpty ? weakTags.first : 'основ';
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Закрепление: $tagLabel',
      description: weakTags.isNotEmpty
          ? 'Подборка для отработки слабого места: $tagLabel'
          : '',
      trainingType: TrainingType.pushFold,
      tags: List<String>.from(weakTags),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      bb: 0,
      positions: [for (final p in positions) p.name],
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }
}
