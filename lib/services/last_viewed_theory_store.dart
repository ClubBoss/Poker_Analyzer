import 'package:shared_preferences/shared_preferences.dart';

class LastViewedTheoryStore {
  LastViewedTheoryStore._();
  static final LastViewedTheoryStore instance = LastViewedTheoryStore._();

  static const _prefix = 'last_viewed_theory_';

  Future<List<String>> _load(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_prefix$packId') ?? <String>[];
  }

  Future<bool> contains(String packId, String lessonId) async {
    final list = await _load(packId);
    return list.contains(lessonId);
  }

  Future<void> add(String packId, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$packId';
    final list = await _load(packId);
    list.remove(lessonId);
    list.insert(0, lessonId);
    if (list.length > 20) list.removeRange(20, list.length);
    await prefs.setStringList(key, list);
  }
}

