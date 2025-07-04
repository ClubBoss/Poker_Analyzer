import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/xp_entry.dart';
import 'xp_tracker_cloud_service.dart';

class XPTrackerService extends ChangeNotifier {
  XPTrackerService({this.cloud});

  static const _xpKey = 'xp_total';
  static const _boxKey = 'xp_history';
  static const targetXp = 10;
  static const achievementXp = 50;

  final XPTrackerCloudService? cloud;

  int _xp = 0;
  Box<dynamic>? _box;
  final List<XPEntry> _history = [];

  void _trim() {
    _history.sort((a, b) => b.date.compareTo(a.date));
    while (_history.length > 100) {
      _history.removeLast();
    }
  }

  Future<void> _persistHistory() async {
    await _box!.clear();
    for (final e in _history) {
      await _box!.put(e.id, e.toJson());
    }
  }

  int get xp => _xp;
  int get level => _xp ~/ 100 + 1;
  int get nextLevelXp => level * 100;
  double get progress => (_xp % 100) / 100;
  List<XPEntry> get history => List.unmodifiable(_history);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!Hive.isBoxOpen(_boxKey)) {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxKey);
    } else {
      _box = Hive.box(_boxKey);
    }
    _history
      ..clear()
      ..addAll(_box!.toMap().entries.where((e) => e.value is Map).map((e) {
        final map = Map<String, dynamic>.from(e.value as Map);
        return XPEntry.fromJson({'id': e.key.toString(), ...map});
      }));
    final remote = await cloud?.loadEntries() ?? [];
    final map = {for (final e in [..._history, ...remote]) e.id: e};
    _history
      ..clear()
      ..addAll(map.values.toList()..sort((a, b) => b.date.compareTo(a.date)));
    _trim();
    _xp = _history.fold(0, (p, e) => p + e.xp);
    await _saveXp();
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _saveXp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _xp);
  }

  Future<void> add({required int xp, required String source, int? streak}) async {
    final entry = XPEntry(
      date: DateTime.now(),
      xp: xp,
      source: source,
      streak: streak ?? 0,
    );
    _history.insert(0, entry);
    _trim();
    _xp += xp;
    await _saveXp();
    await _box!.put(entry.id, entry.toJson());
    await cloud?.saveEntry(entry);
    notifyListeners();
  }
}
