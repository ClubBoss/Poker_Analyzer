import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_hand.dart';

class SavedHandService extends ChangeNotifier {
  static const _storageKey = 'saved_hands';

  final List<SavedHand> _hands = [];
  List<SavedHand> get hands => List.unmodifiable(_hands);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _hands
      ..clear()
      ..addAll(
        raw.map(
          (e) => SavedHand.fromJson(jsonDecode(e) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _hands.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> add(SavedHand hand) async {
    _hands.add(hand);
    await _persist();
    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    _hands.removeAt(index);
    await _persist();
    notifyListeners();
  }

  Future<void> update(int index, SavedHand hand) async {
    if (index < 0 || index >= _hands.length) return;
    _hands[index] = hand;
    await _persist();
    notifyListeners();
  }
}
