import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_auto_generator.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';
import 'package:poker_analyzer/models/texture_filter_config.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/inline_theory_entry.dart';
import 'package:poker_analyzer/services/training_pack_generator_engine_v2.dart';

class _FakeEngine extends TrainingPackGeneratorEngineV2 {
  final List<TrainingPackSpot> out;
  _FakeEngine(this.out);
  @override
  List<TrainingPackSpot> generate(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    int? seed,
  }) => List.from(out);
}

TrainingPackSpot _spot(String id, String board) {
  final cards = [
    board.substring(0, 2),
    board.substring(2, 4),
    board.substring(4, 6),
  ];
  return TrainingPackSpot(
    id: id,
    hand: HandData(board: cards),
    board: cards,
  );
}

void main() {
  test('texture filters include/exclude and mix', () async {
    final engine = _FakeEngine([
      _spot('m', 'KsQsJs'), // monotone
      _spot('r', '2c3d5h'), // rainbow low
      _spot('p', 'AhAd7s'), // paired twoTone
    ]);
    final gen = TrainingPackAutoGenerator(
      engine: engine,
      boardClassifier: const BoardTextureClassifier(),
      textureFilters: const TextureFilterConfig(
        include: {'monotone', 'rainbow'},
        exclude: {'paired'},
        targetMix: {'monotone': 0.5, 'rainbow': 0.5},
      ),
    );
    final set = TrainingPackTemplateSet(baseSpot: TrainingPackSpot(id: 'base'));
    final spots = await gen.generate(set, deduplicate: false);
    expect(spots.map((s) => s.id).toList(), ['m', 'r']);
  });
}
