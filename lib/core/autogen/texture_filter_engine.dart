import 'package:poker_analyzer/services/board_texture_classifier.dart';

/// Filters spots by board texture while enforcing a target mix.
///
/// [flopOf] must return the first three board cards as a six character string
/// such as `'AsKdQc'`. [tolerance] is the allowed percentage overshoot per
/// texture bucket. For example, a `tolerance` of `2` with `spotsPerPack` of 50
/// permits one additional spot above the target allocation.
class TextureFilterEngine {
  /// Filters [spots] based on include/exclude tags and [targetMix].
  ///
  /// [onAccept] and [onReject] are invoked for each texture tag that is
  /// accepted or rejected and present in [targetMix].
  List<T> filter<T>(
    List<T> spots,
    String Function(T) flopOf,
    Set<String> include,
    Set<String> exclude,
    Map<String, double> targetMix, {
    int spotsPerPack = 12,
    int tolerance = 2,
    required BoardTextureClassifier classifier,
    void Function(String)? onAccept,
    void Function(String)? onReject,
  }) {
    final result = <T>[];
    final maxCounts = <String, int>{};
    final counts = <String, int>{};
    final tol = (spotsPerPack * (tolerance / 100)).round();
    targetMix.forEach((k, v) {
      maxCounts[k] = (spotsPerPack * v).round();
    });

    for (final spot in spots) {
      final flop = flopOf(spot);
      final tags = classifier.classify(flop);
      final cards = <String>[
        flop.substring(0, 2),
        flop.substring(2, 4),
        flop.substring(4, 6),
      ];
      final suits = cards.map((c) => c.substring(1)).toSet();
      if (suits.length == 2) tags.add('twoTone');

      if (include.isNotEmpty && include.intersection(tags).isEmpty) {
        for (final t in tags) {
          if (targetMix.containsKey(t)) onReject?.call(t);
        }
        continue;
      }

      if (exclude.intersection(tags).isNotEmpty) {
        for (final t in tags) {
          if (targetMix.containsKey(t)) onReject?.call(t);
        }
        continue;
      }

      var over = false;
      for (final entry in maxCounts.entries) {
        if (tags.contains(entry.key) &&
            (counts[entry.key] ?? 0) >= entry.value + tol) {
          onReject?.call(entry.key);
          over = true;
          break;
        }
      }
      if (over) continue;

      result.add(spot);
      final keys = targetMix.isNotEmpty ? targetMix.keys : tags;
      for (final key in keys) {
        if (tags.contains(key)) {
          onAccept?.call(key);
          if (targetMix.containsKey(key)) {
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }
      }
    }
    return result;
  }
}
