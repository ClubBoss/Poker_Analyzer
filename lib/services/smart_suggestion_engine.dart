import 'training_history_service_v2.dart';
import 'training_pack_filter_engine.dart';
import 'training_gap_detector_service.dart';
import '../models/v2/training_pack_template_v2.dart';

class SmartSuggestionEngine {
  const SmartSuggestionEngine();

  Future<List<TrainingPackTemplateV2>> suggestNext() async {
    final history = await TrainingHistoryServiceV2.getHistory();
    final tags = <String, int>{};
    final audienceCount = <String, int>{};
    final seen = <String>[];
    for (final e in history) {
      if (seen.length < 10) seen.add(e.packId);
      if (e.audience != null && e.audience!.isNotEmpty) {
        audienceCount.update(e.audience!, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final t in e.tags) {
        final key = t.trim().toLowerCase();
        if (key.isNotEmpty) tags.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final sortedTags = tags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selectedTags = [for (final e in sortedTags.take(3)) e.key];
    final gaps = await const TrainingGapDetectorService().detectNeglectedTags();
    for (final g in gaps) {
      if (selectedTags.length >= 3) break;
      if (!selectedTags.contains(g)) selectedTags.add(g);
    }
    final sortedAud = audienceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final audience = sortedAud.isNotEmpty ? sortedAud.first.key : null;
    final engine = const TrainingPackFilterEngine();
    final list = await engine.filter(
      minRating: 70,
      tags: selectedTags.isEmpty ? null : selectedTags,
      audience: audience,
    );
    final exclude = seen.toSet();
    final result = [for (final t in list) if (!exclude.contains(t.id)) t];
    if (result.length < 3 && gaps.isNotEmpty) {
      for (final tag in gaps) {
        final alt = await engine.filter(
          minRating: 70,
          tags: [tag],
          audience: audience,
        );
        for (final t in alt) {
          if (exclude.contains(t.id) || result.contains(t)) continue;
          result.add(t);
          if (result.length >= 3) break;
        }
        if (result.length >= 3) break;
      }
    }
    return result.take(3).toList();
  }
}
