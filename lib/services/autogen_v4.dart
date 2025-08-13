import 'dart:math';

import '../utils/board_textures.dart';
import 'autogen_presets.dart';

/// Generates random board spots for different streets.
///
/// For now only flop boards are supported.
class BoardStreetGenerator {
  final Random _rng;
  final Map<String, double>? _targetMix;

  BoardStreetGenerator({int? seed, Map<String, double>? targetMix})
    : _rng = Random(seed),
      _targetMix = targetMix;

  /// Generates [count] unique board spots using [preset].
  ///
  /// Each spot is represented as:
  /// `{ 'board': ['Ah','Kd','2c'], 'street': 'flop', 'meta':{} }`.
  List<Map<String, dynamic>> generate({
    required int count,
    required String preset,
  }) {
    final presetMix = kAutogenPresets[preset]?.targetMix ?? const {};
    final targetMix = _targetMix ?? presetMix;
    final spots = <Map<String, dynamic>>[];
    final seen = <String>{};
    final texCounts = <String, int>{};

    while (spots.length < count) {
      final board = _randomFlop();
      final key = (List.of(board)..sort()).join();
      if (seen.contains(key)) continue;

      final textures = classifyFlop(board);
      if (targetMix.isNotEmpty) {
        double score = 0;
        for (final tex in textures) {
          final k = tex.name;
          final desired = targetMix[k] ?? 0;
          final current = spots.isEmpty
              ? 0
              : (texCounts[k] ?? 0) / spots.length;
          score += desired - current;
        }
        score /= textures.length;
        final acceptProb = (0.5 + score).clamp(0.0, 1.0);
        if (_rng.nextDouble() > acceptProb) {
          continue;
        }
      }

      seen.add(key);
      for (final tex in textures) {
        final k = tex.name;
        texCounts[k] = (texCounts[k] ?? 0) + 1;
      }
      spots.add({'board': board, 'street': 'flop', 'meta': {}});
    }

    return spots;
  }

  List<String> _randomFlop() {
    const ranks = [
      'A',
      'K',
      'Q',
      'J',
      'T',
      '9',
      '8',
      '7',
      '6',
      '5',
      '4',
      '3',
      '2',
    ];
    const suits = ['c', 'd', 'h', 's'];
    final deck = [
      for (final r in ranks)
        for (final s in suits) '$r$s',
    ];
    deck.shuffle(_rng);
    return deck.take(3).toList();
  }
}
