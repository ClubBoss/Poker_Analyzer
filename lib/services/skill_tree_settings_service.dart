import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'cloud_preferences_service.dart';

class SkillTreeSettingsService {
  SkillTreeSettingsService._();
  static final SkillTreeSettingsService instance = SkillTreeSettingsService._();

  static const _hideCompletedKey = 'skill_tree_hide_completed_prereqs';

  final ValueNotifier<bool> hideCompletedPrereqs = ValueNotifier(false);
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final cloudVal =
        await CloudPreferencesService.instance.getBool(_hideCompletedKey);
    final localVal = prefs.getBool(_hideCompletedKey);
    final value = cloudVal ?? localVal ?? false;
    hideCompletedPrereqs.value = value;
    await prefs.setBool(_hideCompletedKey, value);
    _loaded = true;
  }

  Future<void> setHideCompletedPrereqs(bool value) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_hideCompletedKey, value);
    hideCompletedPrereqs.value = value;
    await CloudPreferencesService.instance.setBool(_hideCompletedKey, value);
  }
}

