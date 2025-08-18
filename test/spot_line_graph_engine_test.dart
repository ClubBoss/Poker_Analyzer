import 'package:test/test.dart';
import 'package:poker_analyzer/services/spot_line_graph_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  test('build converts hand actions into a single line', () {
    final spot = TrainingPackSpot(
      id: 's',
      hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10),
    );
    final engine = const SpotLineGraphEngine();
    final graph = engine.build(spot);
    final lines = graph.getAllLines();
    expect(lines.length, 1);
    expect(lines.first.actions.map((e) => e.action).toList(), ['push', 'fold']);
  });

  test('build adds hero options at terminal node', () {
    final spot = TrainingPackSpot(
      id: 's2',
      hand: HandData(),
      heroOptions: const ['call', 'fold'],
      correctAction: 'call',
    );
    final engine = const SpotLineGraphEngine();
    final graph = engine.build(spot);
    final lines = graph.getAllLines();
    expect(lines.length, 2);
    expect(
      lines.any(
        (l) =>
            l.actions.length == 1 &&
            l.actions.first.action == 'call' &&
            l.actions.first.correct == true,
      ),
      isTrue,
    );
  });
}
