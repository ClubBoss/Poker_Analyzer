import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

enum PackSort { nameAsc, lastPlayed, difficulty, updatedDesc }

class PackSortController extends ValueNotifier<PackSort> {
  PackSortController() : super(PackSort.nameAsc);
  static const _key = 'pack_sort';
  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final idx = prefs.getInt(_key);
    if (idx != null && idx >= 0 && idx < PackSort.values.length) {
      value = PackSort.values[idx];
    }
  }

  Future<void> setSort(PackSort sort) async {
    if (value == sort) return;
    value = sort;
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_key, sort.index);
  }
}
