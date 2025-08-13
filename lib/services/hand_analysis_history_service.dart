import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hand_analysis_record.dart';

class HandAnalysisHistoryService extends ChangeNotifier {
  static const _key = 'hand_analysis_history';
  final List<HandAnalysisRecord> _records = [];

  List<HandAnalysisRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          _records
            ..clear()
            ..addAll(list.map((e) => HandAnalysisRecord.fromJson(
                Map<String, dynamic>.from(e as Map))));
          _records.sort((a, b) => b.date.compareTo(a.date));
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode([for (final r in _records) r.toJson()]));
  }

  Future<void> add(HandAnalysisRecord r) async {
    _records.insert(0, r);
    if (_records.length > 50) _records.removeRange(50, _records.length);
    await _save();
    notifyListeners();
  }
}
