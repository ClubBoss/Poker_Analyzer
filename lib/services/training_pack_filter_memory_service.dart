import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/hero_position.dart';

class TrainingPackFilterMemoryService {
  TrainingPackFilterMemoryService._();

  static final instance = TrainingPackFilterMemoryService._();

  static const _prefsKey = 'training_pack_filter_memory';

  Set<String> selectedTags = {};
  Set<int> stackFilters = {};
  Set<HeroPosition> positionFilters = {};
  String? difficulty;
  bool groupByTag = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null) return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      selectedTags = {
        for (final t in json['tags'] as List? ?? []) t as String
      };
      stackFilters = {
        for (final i in json['stack'] as List? ?? []) i as int
      };
      positionFilters = {
        for (final p in json['pos'] as List? ?? [])
          HeroPosition.values.byName(p as String)
      };
      difficulty = json['difficulty'] as String?;
      groupByTag = json['groupByTag'] as bool? ?? false;
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode({
      'tags': selectedTags.toList(),
      'stack': stackFilters.toList(),
      'pos': [for (final p in positionFilters) p.name],
      'difficulty': difficulty,
      'groupByTag': groupByTag,
    });
    await prefs.setString(_prefsKey, jsonStr);
  }

  Future<void> reset() async {
    selectedTags.clear();
    stackFilters.clear();
    positionFilters.clear();
    difficulty = null;
    groupByTag = false;
    await save();
  }

  Future<void> update({
    required Set<String> tags,
    required Set<int> stack,
    required Set<HeroPosition> pos,
    required String? difficulty,
    required bool groupByTag,
  }) async {
    selectedTags = {...tags};
    stackFilters = {...stack};
    positionFilters = {...pos};
    this.difficulty = difficulty;
    this.groupByTag = groupByTag;
    await save();
  }
}
