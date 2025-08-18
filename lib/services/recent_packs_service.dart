import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_template.dart';

class RecentPack {
  final String id;
  final String name;
  final DateTime lastOpenedAt;

  RecentPack({
    required this.id,
    required this.name,
    required this.lastOpenedAt,
  });

  factory RecentPack.fromJson(Map<String, dynamic> json) {
    return RecentPack(
      id: json['id'] as String,
      name: json['name'] as String,
      lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
  };
}

class RecentPacksService {
  RecentPacksService._();
  static final RecentPacksService instance = RecentPacksService._();

  static const _prefsKey = 'recent_packs_v1';
  final ValueNotifier<List<RecentPack>> _recents =
      ValueNotifier<List<RecentPack>>([]);
  ValueListenable<List<RecentPack>> get listenable => _recents;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null) {
      final items = raw
          .map(
            (e) => RecentPack.fromJson(jsonDecode(e) as Map<String, dynamic>),
          )
          .toList();
      items.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      _recents.value = items;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _recents.value.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> record(TrainingPackTemplate template, {DateTime? when}) async {
    final time = when ?? DateTime.now();
    final list = List<RecentPack>.from(_recents.value);
    list.removeWhere((e) => e.id == template.id);
    list.insert(
      0,
      RecentPack(id: template.id, name: template.name, lastOpenedAt: time),
    );
    if (list.length > 5) {
      list.removeRange(5, list.length);
    }
    _recents.value = list;
    await _save();
  }

  Future<void> remove(String id) async {
    final list = List<RecentPack>.from(_recents.value)
      ..removeWhere((e) => e.id == id);
    _recents.value = list;
    await _save();
  }

  @visibleForTesting
  Future<void> reset() async {
    _recents.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
