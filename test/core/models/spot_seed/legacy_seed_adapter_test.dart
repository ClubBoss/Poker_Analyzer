import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/models/spot_seed/legacy_seed_adapter.dart';
import 'package:poker_analyzer/core/models/spot_seed/spot_seed_codec.dart';
import 'package:poker_analyzer/core/models/spot_seed/spot_seed_validator.dart';

void main() {
  test('legacy map converts and validates', () {
    final legacy = {
      'id': 'L1',
      'gameType': 'tournament',
      'bb': 100,
      'stackBB': 20,
      'position': 'sb',
      'board': ['Ah', 'Kd', 'Qs'],
      'pot': 1,
      'tags': ['FOO', 'foo', 'Bar'],
    };
    const adapter = LegacySeedAdapter();
    final seed = adapter.convert(Map<String, dynamic>.from(legacy));
    expect(seed.tags, ['foo', 'bar']);
    const codec = SpotSeedCodec();
    final round = codec.fromJson(codec.toJson(seed));
    const validator = SpotSeedValidator();
    final issues = validator.validate(round);
    expect(issues.where((i) => i.severity == 'error'), isEmpty);
  });
}

