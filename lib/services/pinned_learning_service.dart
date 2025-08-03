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

  PinnedLearningItem? _find(String type, String id) {
    for (final e in _items) {
      if (e.type == type && e.id == id) return e;
    }
    return null;
  }

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
      _items.insert(0, PinnedLearningItem(type: type, id: id));
    }
    await _save();
    notifyListeners();
  }

  Future<void> unpin(String type, String id) async {
    _items.removeWhere((e) => e.type == type && e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> moveToTop(String type, String id) async {
    final index = _items.indexWhere((e) => e.type == type && e.id == id);
    if (index >= 0) {
      final item = _items.removeAt(index);
      _items.insert(0, item);
      await _save();
      notifyListeners();
    }
  }

  int? lastPosition(String type, String id) => _find(type, id)?.lastPosition;

  Future<void> setLastPosition(String type, String id, int position) async {
    for (var i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e.type == type && e.id == id) {
        _items[i] = e.copyWith(lastPosition: position);
        await _save();
        notifyListeners();
        break;
      }
    }
  }

  Future<void> recordOpen(String type, String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e.type == type && e.id == id) {
        _items[i] = e.copyWith(
          lastSeen: now,
          openCount: e.openCount + 1,
        );
        await _save();
        notifyListeners();
        break;
      }
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final item = _items.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    _items.insert(newIndex, item);
    await _save();
    notifyListeners();
  }
}
