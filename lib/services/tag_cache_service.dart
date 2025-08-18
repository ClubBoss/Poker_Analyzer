import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class TagCacheService extends ChangeNotifier {
  static const kFixedTagOrder = ['Push/Fold', 'ICM', 'Blind Defense'];
  TagCacheService._();
  static final TagCacheService instance = TagCacheService._();
  factory TagCacheService() => instance;

  Map<String, int> topTags = {};
  Map<String, int> topCategories = {};
  bool _loaded = false;

  List<String> get popularTags => List.unmodifiable(_sortedTags());
  List<String> get popularCategories => List.unmodifiable(topCategories.keys);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await rootBundle.loadString(
        'assets/packs/v2/tag_frequencies.json',
      );
      final data = jsonDecode(raw) as Map<String, dynamic>;
      topTags = Map<String, int>.from(
        (data['tags'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );
      topCategories = Map<String, int>.from(
        (data['categories'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );
    } catch (_) {
      topTags = {};
      topCategories = {};
    }
    notifyListeners();
  }

  List<String> getPopularTags({int limit = 10}) => _sortedTags(limit: limit);

  List<String> getPopularCategories({int limit = 5}) =>
      topCategories.keys.take(limit).toList();

  List<String> _sortedTags({int? limit}) {
    final map = {
      for (var i = 0; i < kFixedTagOrder.length; i++) kFixedTagOrder[i]: i,
    };
    final list = topTags.entries.toList()
      ..sort((a, b) {
        final ai = map[a.key];
        final bi = map[b.key];
        if (ai != null || bi != null) {
          if (ai == null) return 1;
          if (bi == null) return -1;
          return ai.compareTo(bi);
        }
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });
    return [for (final e in list.take(limit ?? list.length)) e.key];
  }
}
