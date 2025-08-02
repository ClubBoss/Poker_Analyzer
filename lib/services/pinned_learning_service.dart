import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pinned_learning_item.dart';

class PinnedLearningService extends ChangeNotifier {
  PinnedLearningService._();
  static final PinnedLearningService instance = PinnedLearningService._();

  static const _prefsKey = 'pinned_learning_items';

  final List<PinnedLearningItem> _items = [];

  List<PinnedLearningItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items
      ..clear();
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          _items.add(
            PinnedLearningItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          );
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  bool isPinned(String type, String id) {
    return _items.any((e) => e.type == type && e.id == id);
  }

  Future<void> toggle(String type, String id) async {
    if (isPinned(type, id)) {
      _items.removeWhere((e) => e.type == type && e.id == id);
    } else {
      _items.add(PinnedLearningItem(type: type, id: id));
    }
    await _save();
    notifyListeners();
  }

  Future<void> unpin(String type, String id) async {
    _items.removeWhere((e) => e.type == type && e.id == id);
    await _save();
    notifyListeners();
  }
}
