import 'package:collection/collection.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'pack_similarity_engine.dart';
import 'session_log_service.dart';
import 'training_pack_stats_service.dart';

/// Suggests personalized training packs based on recent performance.
class SmartSuggestionEngine {
  final SessionLogService logs;
  SmartSuggestionEngine({required this.logs});

  List<TrainingPackTemplateV2>? _cache;
  DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns up to five recommended packs.
  /// Results are cached for a short period to avoid heavy computation.
  Future<List<TrainingPackTemplateV2>> suggestNextPacks({bool force = false}) async {
    if (!force &&
        _cache != null &&
        DateTime.now().difference(_cacheTime) < const Duration(hours: 6)) {
      return _cache!;
    }

    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final prefs = await PreferencesService.getInstance();

    final recentMistakes = logs.getRecentMistakes();
    final mistakeTags =
        recentMistakes.keys.map((e) => e.trim().toLowerCase()).toSet();

    final audienceCount = <String, int>{};
    for (final log in logs.logs.take(20)) {
      final tpl = library.firstWhereOrNull((t) => t.id == log.templateId);
      final aud = tpl?.audience ?? tpl?.meta['audience']?.toString();
      if (aud != null && aud.isNotEmpty) {
        audienceCount.update(aud, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    String? preferredAudience;
    if (audienceCount.isNotEmpty) {
      final sorted = audienceCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      preferredAudience = sorted.first.key;
    }

    final entries = <MapEntry<TrainingPackTemplateV2, double>>[];
    for (final pack in library) {
      var score = 0.0;
      final completed = prefs.getBool('completed_tpl_${pack.id}') ?? false;
      if (!completed) score += 1.0;

      if (preferredAudience != null &&
          pack.audience != null &&
          pack.audience == preferredAudience) {
        score += 0.5;
      }

      for (final tag in pack.tags) {
        final key = tag.trim().toLowerCase();
        final cnt = recentMistakes[key];
        if (cnt != null) {
          score += 1 + cnt * 0.1;
        }
      }

      final stat = await TrainingPackStatsService.getStats(pack.id);
      final ev = stat == null
          ? 100.0
          : (stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct);
      if (ev < 80) score += (80 - ev) / 20;
      if (stat != null && stat.accuracy < .8) {
        score += (0.8 - stat.accuracy) * 2;
      }

      if (score > 0) entries.add(MapEntry(pack, score));
    }

    entries.sort((a, b) => b.value.compareTo(a.value));

    const similarity = PackSimilarityEngine();
    final added = <String>{for (final e in entries) e.key.id};
    final similar = <MapEntry<TrainingPackTemplateV2, double>>[];
    for (final e in entries.take(3)) {
      final sims = similarity.findSimilar(e.key.id);
      for (final s in sims) {
        if (added.contains(s.id)) continue;
        if (prefs.getBool('completed_tpl_${s.id}') ?? false) continue;
        similar.add(MapEntry(s, e.value * 0.5));
        added.add(s.id);
      }
    }
    entries.addAll(similar);
    entries.sort((a, b) => b.value.compareTo(a.value));

    _cache = [for (final e in entries.take(5)) e.key];
    _cacheTime = DateTime.now();
    return _cache!;
  }
}
