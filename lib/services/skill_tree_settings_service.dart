import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkillTreeSettingsService {
  SkillTreeSettingsService._();
  static final SkillTreeSettingsService instance = SkillTreeSettingsService._();

  static const _hideCompletedKey = 'skill_tree_hide_completed_prereqs';

  final ValueNotifier<bool> hideCompletedPrereqs = ValueNotifier(false);
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    hideCompletedPrereqs.value = prefs.getBool(_hideCompletedKey) ?? false;
    _loaded = true;
  }

  Future<void> setHideCompletedPrereqs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideCompletedKey, value);
    hideCompletedPrereqs.value = value;
  }
}

