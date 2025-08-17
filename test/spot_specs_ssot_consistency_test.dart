import 'package:test/test.dart';

import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';

void main() {
  test('isAutoReplayKind <=> autoReplayKinds.contains', () {
    for (final k in SpotKind.values) {
      expect(isAutoReplayKind(k), autoReplayKinds.contains(k));
    }
  });

  test('actionsMap and subtitlePrefix have identical key sets', () {
    expect(actionsMap.keys.toSet(), subtitlePrefix.keys.toSet());
  });

  test('All subtitle prefixes end with " • "', () {
    for (final p in subtitlePrefix.values) {
      expect(p.isNotEmpty, true);
      expect(p.endsWith(' • '), true);
    }
  });
}
