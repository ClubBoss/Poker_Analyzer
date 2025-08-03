import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/v2/hero_position.dart';

class TrainingPackFilterMemoryService {
  TrainingPackFilterMemoryService._();

  static final instance = TrainingPackFilterMemoryService._();

  static const _prefsKey = 'training_pack_filter_memory';

  Set<String> selectedTags = {};
  Set<int> stackFilters = {};
  Set<HeroPosition> positionFilters = {};
  Set<String> themeFilters = {};
  String? difficulty;
  bool groupByTag = false;
  bool groupByPosition = false;
  bool groupByStack = false;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null) return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      selectedTags = {for (final t in json['tags'] as List? ?? []) t as String};
      stackFilters = {for (final i in json['stack'] as List? ?? []) i as int};
      positionFilters = {
        for (final p in json['pos'] as List? ?? [])
          HeroPosition.values.byName(p as String)
      };
      themeFilters = {for (final t in json['themes'] as List? ?? []) t as String};
      difficulty = json['difficulty'] as String?;
      groupByTag = json['groupByTag'] as bool? ?? false;
      groupByPosition = json['groupByPosition'] as bool? ?? false;
      groupByStack = json['groupByStack'] as bool? ?? false;
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await PreferencesService.getInstance();
    final jsonStr = jsonEncode({
      'tags': selectedTags.toList(),
      'stack': stackFilters.toList(),
      'pos': [for (final p in positionFilters) p.name],
      'themes': themeFilters.toList(),
      'difficulty': difficulty,
      'groupByTag': groupByTag,
      'groupByPosition': groupByPosition,
      'groupByStack': groupByStack,
    });
    await prefs.setString(_prefsKey, jsonStr);
  }

  Future<void> reset() async {
    selectedTags.clear();
    stackFilters.clear();
    positionFilters.clear();
    themeFilters.clear();
    difficulty = null;
    groupByTag = false;
    groupByPosition = false;
    groupByStack = false;
    await save();
  }

  Future<void> update({
    required Set<String> tags,
    required Set<int> stack,
    required Set<HeroPosition> pos,
    required Set<String> themes,
    required String? difficulty,
    required bool groupByTag,
    required bool groupByPosition,
    required bool groupByStack,
  }) async {
    selectedTags = {...tags};
    stackFilters = {...stack};
    positionFilters = {...pos};
    themeFilters = {...themes};
    this.difficulty = difficulty;
    this.groupByTag = groupByTag;
    this.groupByPosition = groupByPosition;
    this.groupByStack = groupByStack;
    await save();
  }
}
