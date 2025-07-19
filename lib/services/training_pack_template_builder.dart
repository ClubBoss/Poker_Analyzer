import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';

class TrainingPackTemplateBuilder {
  const TrainingPackTemplateBuilder();

  Future<TrainingPackTemplateV2> buildSimplifiedPack(
      List<TrainingPackSpot> mistakes) async {
    await TrainingPackLibraryV2.instance.reload();
    final library = TrainingPackLibraryV2.instance.packs;

    final base = mistakes.take(3).toList();
    final spots = <TrainingPackSpot>[...base];
    for (final m in base) {
      for (final tpl in library) {
        for (final s in tpl.spots) {
          if (s.hand.position == m.hand.position && s.street == m.street) {
            spots.add(TrainingPackSpot.fromJson(s.toJson()));
            break;
          }
        }
        if (spots.length >= base.length + 3) break;
      }
      if (spots.length >= base.length + 3) break;
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Закрепление основ',
      trainingType: TrainingType.pushFold,
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
