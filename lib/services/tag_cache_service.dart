import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class TagCacheService extends ChangeNotifier {
  TagCacheService._();
  static final TagCacheService instance = TagCacheService._();
  factory TagCacheService() => instance;

  Map<String, int> topTags = {};
  Map<String, int> topCategories = {};
  bool _loaded = false;

  List<String> get popularTags => List.unmodifiable(topTags.keys);
  List<String> get popularCategories => List.unmodifiable(topCategories.keys);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw =
          await rootBundle.loadString('assets/packs/v2/tag_frequencies.json');
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

  List<String> getPopularTags({int limit = 10}) =>
      topTags.keys.take(limit).toList();

  List<String> getPopularCategories({int limit = 5}) =>
      topCategories.keys.take(limit).toList();
}
