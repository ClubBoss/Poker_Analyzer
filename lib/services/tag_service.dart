import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagService extends ChangeNotifier {
  static const _prefsKey = 'global_tags';

  List<String> _tags = [];

  List<String> get tags => List.unmodifiable(_tags);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _tags = prefs.getStringList(_prefsKey) ?? [];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _tags);
  }

  Future<void> addTag(String tag) async {
    if (_tags.contains(tag)) return;
    _tags.add(tag);
    await _save();
    notifyListeners();
  }

  Future<void> renameTag(int index, String newTag) async {
    if (index < 0 || index >= _tags.length) return;
    if (_tags.contains(newTag)) return;
    _tags[index] = newTag;
    await _save();
    notifyListeners();
  }

  Future<void> deleteTag(int index) async {
    if (index < 0 || index >= _tags.length) return;
    _tags.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> reorderTags(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _tags.removeAt(oldIndex);
    _tags.insert(newIndex, item);
    await _save();
    notifyListeners();
  }
}
