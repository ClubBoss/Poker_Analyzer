import '../models/line_graph.dart';
import '../models/spot_seed_format.dart';

class LineGraphEngine {
  const LineGraphEngine();

  LineGraph build(SpotSeedFormat seed) {
    final street = seed.currentStreet;
    final actions = seed.villainActions
        .map(
          (a) => LineAction(
            action: _normalize(a),
            position: 'villain',
          ),
        )
        .toList();
    final lineStreet = LineStreet(street: street, actions: actions);
    return LineGraph(heroPosition: seed.position, streets: [lineStreet]);
  }

  String _normalize(String action) => action.split(' ').first.toLowerCase();
}
