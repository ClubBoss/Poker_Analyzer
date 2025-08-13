import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PackFilterController extends ChangeNotifier {
  static const _queryKey = 'pack_filter_query';
  static const _catKey = 'pack_filter_categories';
  static const _streetKey = 'pack_filter_streets';
  static const _diffKey = 'pack_filter_difficulties';

  final ValueNotifier<String> query = ValueNotifier('');
  final Set<String> categories = {};
  final Set<String> streets = {};
  final Set<int> difficulties = {};

  SharedPreferences? _prefs;
  Timer? _debounce;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    query.value = _prefs!.getString(_queryKey) ?? '';
    categories
      ..clear()
      ..addAll(_prefs!.getStringList(_catKey) ?? []);
    streets
      ..clear()
      ..addAll(_prefs!.getStringList(_streetKey) ?? []);
    difficulties
      ..clear()
      ..addAll(
          _prefs!.getStringList(_diffKey)?.map(int.tryParse).whereType<int>() ??
              {});
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString(_queryKey, query.value);
    p.setStringList(_catKey, categories.toList());
    p.setStringList(_streetKey, streets.toList());
    p.setStringList(_diffKey, difficulties.map((e) => e.toString()).toList());
  }

  void setQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      query.value = value;
      _save();
      notifyListeners();
    });
  }

  void toggleCategory(String value) {
    if (categories.contains(value)) {
      categories.remove(value);
    } else {
      categories.add(value);
    }
    _save();
    notifyListeners();
  }

  void toggleStreet(String value) {
    if (streets.contains(value)) {
      streets.remove(value);
    } else {
      streets.add(value);
    }
    _save();
    notifyListeners();
  }

  void toggleDifficulty(int value) {
    if (difficulties.contains(value)) {
      difficulties.remove(value);
    } else {
      difficulties.add(value);
    }
    _save();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    query.dispose();
    super.dispose();
  }
}
