import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:collection/collection.dart';

import '../models/session_log.dart';
import 'pack_library_loader_service.dart';

class LearningPathPersonalizationService {
  LearningPathPersonalizationService._();
  static final instance = LearningPathPersonalizationService._();

  static const _skillKey = 'learning_tag_skill_map';
  final Map<String, double> _skills = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_skillKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _skills
            ..clear()
            ..addAll({
              for (final e in data.entries)
                e.key.toString(): (e.value as num).toDouble()
            });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_skillKey, jsonEncode(_skills));
  }

  Future<void> updateFromSession(SessionLog session) async {
    await _load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final tpl = library.firstWhereOrNull((t) => t.id == session.templateId);
    if (tpl == null) return;
    final total = session.correctCount + session.mistakeCount;
    if (total == 0) return;
    final acc = session.correctCount / total;
    const alpha = 0.3;
    final tags = <String>{
      ...tpl.tags.map((e) => e.trim().toLowerCase()),
      if (tpl.category != null) tpl.category!.trim().toLowerCase(),
    }..removeWhere((e) => e.isEmpty);
    for (final tag in tags) {
      final prev = _skills[tag] ?? 0.5;
      final updated = alpha * acc + (1 - alpha) * prev;
      _skills[tag] = double.parse(updated.toStringAsFixed(4));
    }
    await _save();
  }

  Map<String, double> getTagSkillMap() => Map.unmodifiable(_skills);

  List<String> getWeakestTags({int limit = 3}) {
    final entries = _skills.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in entries.take(limit)) e.key];
  }
}
