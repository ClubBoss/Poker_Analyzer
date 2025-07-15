import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_template.dart';
import 'template_storage_service.dart';

class TagCacheService extends ChangeNotifier {
  static const _tagsKey = 'tag_cache_tags';
  static const _catsKey = 'tag_cache_cats';

  final TemplateStorageService templates;
  List<String> _popularTags = [];
  List<String> _popularCategories = [];

  List<String> get popularTags => List.unmodifiable(_popularTags);
  List<String> get popularCategories => List.unmodifiable(_popularCategories);

  TagCacheService({required this.templates}) {
    templates.addListener(_update);
    _load();
    _update();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _popularTags = prefs.getStringList(_tagsKey) ?? [];
    _popularCategories = prefs.getStringList(_catsKey) ?? [];
  }

  Future<void> updateFrom(List<TrainingPackTemplate> list) async {
    final tagCounts = <String, int>{};
    final catCounts = <String, int>{};
    for (final t in list) {
      for (final tag in t.tags) {
        tagCounts.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final h in t.hands) {
        final c = h.category;
        if (c != null && c.isNotEmpty) {
          catCounts.update(c, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
    final tags = tagCounts.keys.toList()
      ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));
    final cats = catCounts.keys.toList()
      ..sort((a, b) => catCounts[b]!.compareTo(catCounts[a]!));
    _popularTags = tags.take(20).toList();
    _popularCategories = cats.take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tagsKey, _popularTags);
    await prefs.setStringList(_catsKey, _popularCategories);
    notifyListeners();
  }

  Future<void> _update() => updateFrom(templates.templates);

  @override
  void dispose() {
    templates.removeListener(_update);
    super.dispose();
  }
}
