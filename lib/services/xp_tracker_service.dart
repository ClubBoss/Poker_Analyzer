import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/xp_entry.dart';

class XPTrackerService extends ChangeNotifier {
  static const _xpKey = 'xp_total';
  static const _boxKey = 'xp_history';
  static const targetXp = 10;
  static const achievementXp = 50;

  int _xp = 0;
  Box<dynamic>? _box;
  final List<XPEntry> _history = [];

  int get xp => _xp;
  int get level => _xp ~/ 100 + 1;
  int get nextLevelXp => level * 100;
  double get progress => (_xp % 100) / 100;
  List<XPEntry> get history => List.unmodifiable(_history);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt(_xpKey) ?? 0;
    if (!Hive.isBoxOpen(_boxKey)) {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxKey);
    } else {
      _box = Hive.box(_boxKey);
    }
    _history
      ..clear()
      ..addAll(_box!.values
          .whereType<Map>()
          .map((e) => XPEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList()
            ..sort((a, b) => b.date.compareTo(a.date)));
    notifyListeners();
  }

  Future<void> _saveXp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _xp);
  }

  Future<void> add({required int xp, required String source, int? streak}) async {
    _xp += xp;
    await _saveXp();
    final entry = XPEntry(
      date: DateTime.now(),
      xp: xp,
      source: source,
      streak: streak ?? 0,
    );
    _history.insert(0, entry);
    await _box!.put(entry.date.millisecondsSinceEpoch, entry.toJson());
    notifyListeners();
  }
}
