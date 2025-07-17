import 'training_history_service_v2.dart';
import 'training_pack_filter_engine.dart';
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
    final sortedAud = audienceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final audience = sortedAud.isNotEmpty ? sortedAud.first.key : null;
    final list = await const TrainingPackFilterEngine().filter(
      minRating: 70,
      tags: selectedTags.isEmpty ? null : selectedTags,
      audience: audience,
    );
    final exclude = seen.toSet();
    final result = [for (final t in list) if (!exclude.contains(t.id)) t];
    return result.take(3).toList();
  }
}
