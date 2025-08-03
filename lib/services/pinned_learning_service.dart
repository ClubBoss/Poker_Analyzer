import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pinned_learning_item.dart';
import '../models/theory_block_model.dart';
import 'theory_block_library_service.dart';

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
    if (type == 'block') {
      final block =
          TheoryBlockLibraryService.instance.getById(id) ?? TheoryBlockModel(
            id: id,
            title: '',
            nodeIds: const [],
            practicePackIds: const [],
          );
      await toggleBlock(block);
      return;
    }

    if (isPinned(type, id)) {
      _items.removeWhere((e) => e.type == type && e.id == id);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await TheoryBlockLibraryService.instance.loadAll();
      for (final b in TheoryBlockLibraryService.instance.all) {
        if ((type == 'lesson' && b.nodeIds.contains(id)) ||
            (type == 'pack' && b.practicePackIds.contains(id))) {
          _items.removeWhere((e) => e.type == 'block' && e.id == b.id);
          await prefs.remove('pinned_block_${b.id}');
        }
      }
      _items.insert(0, PinnedLearningItem(type: type, id: id));
    }
    await _save();
    notifyListeners();
  }

  Future<void> toggleBlock(TheoryBlockModel block) async {
    final id = block.id;
    final prefs = await SharedPreferences.getInstance();
    if (isPinned('block', id)) {
      _items.removeWhere((e) => e.type == 'block' && e.id == id);
      await prefs.remove('pinned_block_$id');
    } else {
      _items.removeWhere((e) =>
          (e.type == 'lesson' && block.nodeIds.contains(e.id)) ||
          (e.type == 'pack' && block.practicePackIds.contains(e.id)));
      await prefs.setBool('pinned_block_$id', true);
      _items.insert(0, PinnedLearningItem(type: 'block', id: id));
    }
    await _save();
    notifyListeners();
  }

  Future<void> unpin(String type, String id) async {
    _items.removeWhere((e) => e.type == type && e.id == id);
    if (type == 'block') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pinned_block_$id');
    }
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
