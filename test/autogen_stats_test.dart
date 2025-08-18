import 'dart:convert';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_stats.dart';

void main() {
  test('buildAutogenStats tallies textures', () {
    final report = json.encode({
      'spots': [
        {'board': 'AhKd2c'},
        {
          'board': ['Td', '9d', '8d'],
        },
      ],
    });
    final stats = buildAutogenStats(report);
    expect(stats, isNotNull);
    expect(stats!.total, 2);
    expect(stats.textures['aceHigh'], 1);
    expect(stats.textures['rainbow'], 1);
    expect(stats.textures['broadwayHeavy'], 1);
    expect(stats.textures['monotone'], 1);
  });
}
