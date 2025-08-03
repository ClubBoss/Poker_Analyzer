import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/line_graph_engine.dart';
import 'package:poker_analyzer/models/line_graph_request.dart';

void main() {
  test('generates action lines with required tags', () {
    final engine = LineGraphEngine(seed: 1);
    final lines = engine.generate(
      const LineGraphRequest(
        gameStage: 'turn',
        requiredTags: ['probe'],
        minActions: 2,
        maxActions: 10,
      ),
    );
    expect(lines.isNotEmpty, true);
    expect(lines.first.tags.contains('probe'), true);
    expect(lines.first.actions.length >= 2, true);
  });
}
