import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_hand.dart';
import 'cloud_sync_service.dart';

class SavedHandStorageService extends ChangeNotifier {
  static const _storageKey = 'saved_hands';
  static const _timeKey = 'saved_hands_updated';

  SavedHandStorageService({this.cloud});

  final CloudSyncService? cloud;

  final List<SavedHand> _hands = [];
  List<SavedHand> get hands => List.unmodifiable(_hands);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _hands
      ..clear()
      ..addAll(raw.map(
          (e) => SavedHand.fromJson(jsonDecode(e) as Map<String, dynamic>)));
    if (cloud != null) {
      final remote = cloud!.getCached('saved_hands');
      if (remote != null) {
        final remoteAt =
            DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final localAt = DateTime.tryParse(prefs.getString(_timeKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          final list = remote['hands'];
          if (list is List) {
            _hands
              ..clear()
              ..addAll(list.map((e) =>
                  SavedHand.fromJson(Map<String, dynamic>.from(e as Map))));
            await _persist();
          }
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadHands(_hands);
        }
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _hands.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
    if (cloud != null) {
      await cloud!.uploadHands(_hands);
    }
  }

  Future<void> add(SavedHand hand) async {
    _hands.add(hand);
    await _persist();
    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _hands.length) return;
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
