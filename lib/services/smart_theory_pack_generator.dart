import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import '../models/pack_library.dart';
import '../core/training/engine/training_type_engine.dart';

/// Auto-generates a simple theory pack for a given tag.
class SmartTheoryPackGenerator {
  SmartTheoryPackGenerator();

  List<TrainingPackSpot> _buildTemplate(String tag, String idPrefix) {
    final explanation = 'This is a theory module about $tag';
    return [
      TrainingPackSpot(
        id: '${idPrefix}_1',
        type: 'theory',
        title: 'A9o push',
        explanation: explanation,
        tags: [tag],
        hand: HandData.fromSimpleInput('As 9d', HeroPosition.sb, 10),
      ),
      TrainingPackSpot(
        id: '${idPrefix}_2',
        type: 'theory',
        title: 'Q6s fold',
        explanation: explanation,
        tags: [tag],
        hand: HandData(
          heroCards: 'Qs 6s',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: const {'0': 10, '1': 10},
          actions: {
            0: [ActionEntry(0, 0, 'fold')],
          },
        ),
      ),
      TrainingPackSpot(
        id: '${idPrefix}_3',
        type: 'theory',
        title: '22 push call',
        explanation: explanation,
        tags: [tag],
        hand: HandData(
          heroCards: '2c 2d',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: const {'0': 10, '1': 10},
          actions: {
            0: [
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'call', amount: 9.5),
            ],
          },
        ),
      ),
      TrainingPackSpot(
        id: '${idPrefix}_4',
        type: 'theory',
        title: 'J9s push',
        explanation: explanation,
        tags: [tag],
        hand: HandData.fromSimpleInput('Jh 9h', HeroPosition.sb, 10),
      ),
      TrainingPackSpot(
        id: '${idPrefix}_5',
        type: 'theory',
        title: 'KTo push',
        explanation: explanation,
        tags: [tag],
        hand: HandData.fromSimpleInput('Kh Td', HeroPosition.sb, 10),
      ),
    ];
  }

  /// Builds a theory pack for [tag] unless it already exists in [PackLibrary].
  Future<TrainingPackTemplateV2> generateTheoryPack(String tag) async {
    final key = tag.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final id = 'theory_$key';
    final existing =
        PackLibrary.main.getById(id) ?? PackLibrary.staging.getById(id);
    if (existing != null) return existing;

    final spots = _buildTemplate(tag, id);
    final tpl = TrainingPackTemplateV2(
      id: id,
      name: 'Теория: $tag',
      trainingType: TrainingType.theory,
      tags: [tag],
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      meta: const {'schemaVersion': '2.0.0'},
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }
}
