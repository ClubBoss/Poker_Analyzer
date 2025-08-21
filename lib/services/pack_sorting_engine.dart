import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_completion_service.dart';

/// Provides sorting utilities for training packs.
class PackSortingEngine {
  /// Sorts [packs] by progress. Untrained packs can be prioritized to appear
  /// first when [prioritizeUntrained] is `true`.
  static Future<List<TrainingPackTemplateV2>> sortByProgress(
    List<TrainingPackTemplateV2> packs, {
    bool prioritizeUntrained = true,
  }) async {
    final completions =
        await PackLibraryCompletionService.instance.getAllCompletions();
    final entries = packs.asMap().entries.toList();
    mergeSort<MapEntry<int, TrainingPackTemplateV2>>(
      entries,
      compare: (a, b) {
        final aData = completions[a.value.id];
        final bData = completions[b.value.id];
        if (prioritizeUntrained) {
          final aTrained = aData != null;
          final bTrained = bData != null;
          if (aTrained != bTrained) return aTrained ? 1 : -1;
        }
        final aAcc = aData?.accuracy ?? -1.0;
        final bAcc = bData?.accuracy ?? -1.0;
        final r = aAcc.compareTo(bAcc);
        return r == 0 ? a.key.compareTo(b.key) : r;
      },
    );
    return [for (final e in entries) e.value];
  }

  /// Sorts [packs] by completion accuracy.
  static Future<List<TrainingPackTemplateV2>> sortByAccuracy(
    List<TrainingPackTemplateV2> packs, {
    bool descending = false,
  }) async {
    final completions =
        await PackLibraryCompletionService.instance.getAllCompletions();
    final entries = packs.asMap().entries.toList();
    mergeSort<MapEntry<int, TrainingPackTemplateV2>>(
      entries,
      compare: (a, b) {
        final aAcc = completions[a.value.id]?.accuracy ?? -1.0;
        final bAcc = completions[b.value.id]?.accuracy ?? -1.0;
        final r = descending ? bAcc.compareTo(aAcc) : aAcc.compareTo(bAcc);
        return r == 0 ? a.key.compareTo(b.key) : r;
      },
    );
    return [for (final e in entries) e.value];
  }

  /// Sorts [packs] by the time they were last trained.
  static Future<List<TrainingPackTemplateV2>> sortByLastTrained(
    List<TrainingPackTemplateV2> packs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = packs.asMap().entries.toList();
    mergeSort<MapEntry<int, TrainingPackTemplateV2>>(
      entries,
      compare: (a, b) {
        DateTime parse(String? s) =>
            DateTime.tryParse(s ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final aDt = parse(prefs.getString('last_trained_tpl_${a.value.id}'));
        final bDt = parse(prefs.getString('last_trained_tpl_${b.value.id}'));
        final r = bDt.compareTo(aDt);
        return r == 0 ? a.key.compareTo(b.key) : r;
      },
    );
    return [for (final e in entries) e.value];
  }
}
