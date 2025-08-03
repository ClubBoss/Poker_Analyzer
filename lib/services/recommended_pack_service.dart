import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'saved_hand_manager_service.dart';

class RecommendedPackService extends ChangeNotifier {
  static const _tagsKey = 'preferred_tags';
  static const _catsKey = 'preferred_cats';

  final SavedHandManagerService hands;

  List<String> _preferredTags = [];
  List<String> _preferredCategories = [];

  List<String> get preferredTags => List.unmodifiable(_preferredTags);
  List<String> get preferredCategories => List.unmodifiable(_preferredCategories);

  RecommendedPackService({required this.hands}) {
    _load();
    _update();
    hands.addListener(_update);
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    _preferredTags = prefs.getStringList(_tagsKey) ?? [];
    _preferredCategories = prefs.getStringList(_catsKey) ?? [];
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_tagsKey, _preferredTags);
    await prefs.setStringList(_catsKey, _preferredCategories);
  }

  Future<void> _update() async {
    final recent = hands.hands.reversed.take(50);
    final tagCounts = <String, int>{};
    final catCounts = <String, int>{};
    for (final h in recent) {
      for (final tag in h.tags) {
        tagCounts.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
      final c = h.category;
      if (c != null && c.isNotEmpty) {
        catCounts.update(c, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final tags = tagCounts.keys.toList()
      ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));
    final cats = catCounts.keys.toList()
      ..sort((a, b) => catCounts[b]!.compareTo(catCounts[a]!));
    _preferredTags = tags.take(10).toList();
    _preferredCategories = cats.take(10).toList();
    await _save();
    notifyListeners();
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    super.dispose();
  }
}
