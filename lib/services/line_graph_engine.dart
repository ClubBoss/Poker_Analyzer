import '../models/line_pattern.dart';
import '../models/line_graph_result.dart';

class LineGraphEngine {
  const LineGraphEngine();

  LineGraphResult build(LinePattern pattern) {
    final Map<String, List<HandActionNode>> streets = {};
    final List<String> tags = [];

    pattern.streets.forEach((street, actions) {
      final nodes = <HandActionNode>[];
      for (final act in actions) {
        final actor = _inferActor(act);
        nodes.add(HandActionNode(actor: actor, action: act));
        tags.add('${street}${_capitalize(act)}');
      }
      streets[street] = nodes;
    });

    return LineGraphResult(
      heroPosition: pattern.startingPosition ?? 'hero',
      streets: streets,
      tags: tags,
    );
  }

  String _inferActor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('villain')) {
      return 'villain';
    }
    return 'hero';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
