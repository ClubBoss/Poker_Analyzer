import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/library/training_pack_library_v2.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../utils/shared_prefs_keys.dart';

/// Builds targeted booster packs for weak skill tags.
class TargetedPackBoosterEngine {
  final List<TrainingPackTemplateV2> Function() _packsProvider;
  final Future<SharedPreferences> Function() _prefsProvider;
  final Duration _cooldown;

  TargetedPackBoosterEngine({
    List<TrainingPackTemplateV2> Function()? packsProvider,
    Future<SharedPreferences> Function()? prefsProvider,
    Duration? cooldown,
  })  : _packsProvider =
            packsProvider ?? (() => TrainingPackLibraryV2.instance.packs),
        _prefsProvider = prefsProvider ?? SharedPreferences.getInstance,
        _cooldown = cooldown ?? const Duration(days: 1);

  /// Generates booster packs for [weakTags].
  ///
  /// Each resulting pack includes only spots tagged with the respective
  /// weakness and is titled "Booster — tag".
  Future<List<TrainingPackModel>> generateBoostersFor(
      List<String> weakTags) async {
    if (weakTags.isEmpty) return [];
    final prefs = await _prefsProvider();
    final now = DateTime.now();
    final packs = _packsProvider();
    final result = <TrainingPackModel>[];
    final seen = <String>{};

    for (final rawTag in weakTags) {
      final displayTag = rawTag.trim();
      final tag = displayTag.toLowerCase();
      if (tag.isEmpty || !seen.add(tag)) continue;
      final last = prefs.getInt(SharedPrefsKeys.targetedBoosterLast(tag));
      if (last != null &&
          now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
              _cooldown) {
        continue;
      }

      final spots = <TrainingPackSpot>[];
      for (final p in packs) {
        spots.addAll(p.spots
            .where((s) => s.tags.map((e) => e.toLowerCase()).contains(tag)));
      }
      if (spots.isEmpty) continue;

      final model = TrainingPackModel(
        id: 'booster_${tag}_${now.millisecondsSinceEpoch}',
        title: 'Booster — $displayTag',
        spots: spots,
        tags: [tag, 'booster'],
        metadata: const {'booster': true},
      );
      result.add(model);
      await prefs.setInt(SharedPrefsKeys.targetedBoosterLast(tag),
          now.millisecondsSinceEpoch);
    }
    return result;
  }
}
