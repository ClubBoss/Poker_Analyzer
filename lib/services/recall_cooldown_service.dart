import 'package:shared_preferences/shared_preferences.dart';

class RecallCooldownService {
  RecallCooldownService._(this._prefs, this._now);

  static RecallCooldownService? _instance;

  static Future<RecallCooldownService> get instance async {
    _instance ??= await RecallCooldownService.create();
    return _instance!;
  }

  static Future<RecallCooldownService> create({
    SharedPreferences? prefs,
    DateTime Function()? now,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return RecallCooldownService._(p, now ?? DateTime.now);
  }

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final Map<String, DateTime> _lastShown = {};

  bool canShow(String tag, {Duration cooldown = const Duration(minutes: 10)}) {
    final now = _now();
    final last = _lastShown[tag] ?? _load(tag);
    if (last == null) return true;
    return now.difference(last) >= cooldown;
  }

  Future<void> markShown(String tag) async {
    final now = _now();
    _lastShown[tag] = now;
    await _prefs.setInt(_key(tag), now.millisecondsSinceEpoch);
  }

  DateTime? _load(String tag) {
    final ms = _prefs.getInt(_key(tag));
    if (ms == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    _lastShown[tag] = dt;
    return dt;
  }

  static String _key(String tag) => 'recall_last_shown_' + tag;
}
