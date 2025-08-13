import 'dart:convert';

import '../utils/board_textures.dart';

class AutogenStats {
  final Map<String, int> textures;
  final int total;

  AutogenStats({
    required this.textures,
    required this.total,
  });
}

AutogenStats? buildAutogenStats(String reportJson) {
  try {
    final data = json.decode(reportJson);
    if (data is! Map<String, dynamic>) return null;
    final spots = data['spots'];
    if (spots is! List) return null;

    final textures = <String, int>{};
    var total = 0;

    for (final spot in spots) {
      final board = (spot is Map<String, dynamic>) ? spot['board'] : null;

      List<String>? cards;
      if (board is String) {
        cards = <String>[];
        for (var i = 0; i + 1 < board.length && cards.length < 3; i += 2) {
          cards.add(board.substring(i, i + 2));
        }
      } else if (board is List) {
        cards = board.take(3).cast<String>().toList();
      }

      if (cards == null || cards.length < 3) continue;

      final texSet = classifyFlop(cards);
      for (final tex in texSet) {
        final key = tex.name;
        textures[key] = (textures[key] ?? 0) + 1;
      }
      total++;
    }

    return AutogenStats(textures: textures, total: total);
  } catch (_) {
    return null;
  }
}

