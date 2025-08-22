import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import 'booster_thematic_descriptions.dart';

/// Generates a simple theory training pack for a given [tag].
class TheoryPackGenerator {
  TheoryPackGenerator();

  /// Default text used when no localized strings are provided.
  static const String defaultQuestion = 'Question';
  static const String defaultSolution = 'Solution';
  static const String defaultExplanation = 'Explanation';

  /// Builds a [TrainingPackTemplateV2] with a single theory spot.
  TrainingPackTemplateV2 generate(
    String tag,
    String idPrefix, {
    String question = defaultQuestion,
    String solution = defaultSolution,
    String? explanation,
  }) {
    final resolvedExplanation =
        explanation ??
        BoosterThematicDescriptions.get(tag) ??
        defaultExplanation;
    final spot = TrainingPackSpot(
      id: '${idPrefix}_${tag}_1',
      type: 'theory',
      title: question,
      note: solution,
      explanation: resolvedExplanation,
      tags: [tag],
      hand: HandData(),
    );
    return TrainingPackTemplateV2(
      id: '${idPrefix}_${tag}_theory',
      name: '📘 $tag',
      trainingType: TrainingType.theory,
      tags: [tag],
      spots: [spot],
      spotCount: 1,
      created: DateTime.now(),
      gameType: GameType.tournament,
      meta: const {'schemaVersion': '2.0.0'},
    );
  }
}
