import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/shared_prefs_keys.dart';

class L3RunHistoryEntry {
  final DateTime timestamp;
  final String argsSummary;
  final String outPath;
  final String logPath;
  final List<String> warnings;
  final String? weights;
  final String? preset;

  L3RunHistoryEntry({
    required this.timestamp,
    required this.argsSummary,
    required this.outPath,
    required this.logPath,
    required this.warnings,
    this.weights,
    this.preset,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'args': argsSummary,
        'out': outPath,
        'log': logPath,
        'warnings': warnings,
        if (weights != null) 'weights': weights,
        if (preset != null) 'preset': preset,
      };

  static L3RunHistoryEntry fromJson(Map<String, dynamic> json) =>
      L3RunHistoryEntry(
        timestamp: DateTime.parse(json['ts'] as String),
        argsSummary: json['args'] as String,
        outPath: json['out'] as String,
        logPath: json['log'] as String,
        warnings:
            (json['warnings'] as List?)?.cast<String>() ?? <String>[],
        weights: json['weights'] as String?,
        preset: json['preset'] as String?,
      );
}

class L3RunHistoryService {
  static const _max = 5;

  Future<List<L3RunHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SharedPrefsKeys.l3RunHistory);
    if (raw == null) return [];
    final List list = jsonDecode(raw) as List;
    return list
        .map((e) => L3RunHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> push(L3RunHistoryEntry entry) async {
    final history = await load();
    history.insert(0, entry);
    if (history.length > _max) {
      history.removeRange(_max, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SharedPrefsKeys.l3RunHistory,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }
}

