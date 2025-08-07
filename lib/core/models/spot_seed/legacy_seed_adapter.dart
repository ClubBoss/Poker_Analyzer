import 'spot_seed_codec.dart';
import 'unified_spot_seed_format.dart';

/// Converts legacy seed maps into [SpotSeed] instances.
class LegacySeedAdapter {
  const LegacySeedAdapter({SpotSeedCodec? codec}) : _codec = codec ?? const SpotSeedCodec();

  final SpotSeedCodec _codec;

  /// Convert [legacy] map to [SpotSeed]. If the map already matches the USF
  /// structure it is decoded directly. Otherwise a best effort conversion is
  /// performed from older seed formats. Tags are normalised to lowercase and
  /// duplicates removed.
  SpotSeed convert(Map<String, dynamic> legacy) {
    // If it already looks like USF, just decode using the codec.
    if (legacy.containsKey('gameType') && legacy.containsKey('bb')) {
      final map = Map<String, dynamic>.from(legacy);
      final tags = map['tags'];
      if (tags is List) {
        map['tags'] = _normaliseTags(tags.cast<String>());
      }
      return _codec.fromJson(map);
    }

    final tags = _normaliseTags(
        (legacy['tags'] as List?)?.cast<String>() ?? const <String>[]);
    final id = legacy['id']?.toString() ??
        'legacy_${DateTime.now().millisecondsSinceEpoch}';
    final heroPos = legacy['position']?.toString() ?? 'btn';

    return SpotSeed(
      id: id,
      gameType: legacy['gameType']?.toString() ?? 'tournament',
      bb: (legacy['bb'] as num?)?.toDouble() ?? 1.0,
      stackBB: (legacy['stackBB'] as num?)?.toDouble() ?? 0.0,
      positions: SpotPositions(hero: heroPos),
      ranges: const SpotRanges(),
      board: SpotBoard(
        preflop: (legacy['board'] as List?)?.cast<String>(),
      ),
      pot: (legacy['pot'] as num?)?.toDouble() ?? 0.0,
      tags: tags,
    );
  }

  List<String> _normaliseTags(List<String> tags) {
    final set = <String>{};
    for (final t in tags) {
      set.add(t.toLowerCase());
    }
    return set.toList();
  }
}

