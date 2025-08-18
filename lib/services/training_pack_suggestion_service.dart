import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'training_pack_filter_engine.dart';
import 'session_log_service.dart';

class TrainingPackSuggestionService {
  final SessionLogService history;
  final TrainingPackFilterEngine engine;
  const TrainingPackSuggestionService({
    required this.history,
    this.engine = const TrainingPackFilterEngine(),
  });

  Future<List<TrainingPackTemplateV2>> suggestNext({
    required String userId,
  }) async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final recent = history.logs.take(3).toList();
    if (recent.isEmpty) return [];
    final List<TrainingPackTemplateV2> last = [];
    for (final log in recent) {
      final tpl = library.firstWhereOrNull((t) => t.id == log.templateId);
      if (tpl != null) last.add(tpl);
    }
    if (last.isEmpty) return [];
    final tags = <String, int>{};
    String? audience;
    final diffs = <double>[];
    for (final t in last) {
      if (t.audience != null && t.audience!.isNotEmpty) {
        audience ??= t.audience!;
      }
      for (final tag in t.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isNotEmpty) tags.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
      final d =
          (t.meta['rankScore'] as num?)?.toDouble() ??
          (t.meta['difficulty'] as num?)?.toDouble();
      if (d != null) diffs.add(d);
    }
    final sorted = tags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selectedTags = [for (final e in sorted.take(3)) e.key];
    final result = await engine.filter(
      tags: selectedTags.isEmpty ? null : selectedTags,
      audience: audience,
    );
    final used = last.map((e) => e.id).toSet();
    final list = [
      for (final r in result)
        if (!used.contains(r.id)) r,
    ];
    if (diffs.isNotEmpty) {
      final avg = diffs.reduce((a, b) => a + b) / diffs.length;
      list.sort((a, b) {
        final ad =
            ((a.meta['rankScore'] as num?)?.toDouble() ??
                (a.meta['difficulty'] as num?)?.toDouble() ??
                avg) -
            avg;
        final bd =
            ((b.meta['rankScore'] as num?)?.toDouble() ??
                (b.meta['difficulty'] as num?)?.toDouble() ??
                avg) -
            avg;
        return ad.abs().compareTo(bd.abs());
      });
    }
    return list.take(5).toList();
  }
}
