import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theory_link_config_service.dart';

class TheoryLinkPolicyEngine {
  TheoryLinkPolicyEngine({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  Future<bool> canInject(String userId, Set<String> demandTags) async {
    final cfg = TheoryLinkConfigService.instance.value;
    final sessionKey = 'theory.cap.session.$userId';
    final sessionCount = _prefs.getInt(sessionKey) ?? 0;
    if (sessionCount >= cfg.perSessionCap) return false;

    final date = DateFormat('yyyyMMdd').format(DateTime.now().toUtc());
    final dayKey = 'theory.cap.day.$userId.$date';
    final dayCount = _prefs.getInt(dayKey) ?? 0;
    if (dayCount >= cfg.perDayCap) return false;

    final now = DateTime.now().toUtc();
    for (final tag in demandTags) {
      final key = 'theory.tag.last.$userId.$tag';
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      final last = DateTime.tryParse(raw);
      if (last != null &&
          now.difference(last) < Duration(hours: cfg.perTagCooldownHours)) {
        return false;
      }
    }
    return true;
  }

  Future<void> onInjected(String userId, Set<String> demandTags) async {
    final sessionKey = 'theory.cap.session.$userId';
    final sessionCount = (_prefs.getInt(sessionKey) ?? 0) + 1;
    await _prefs.setInt(sessionKey, sessionCount);

    final date = DateFormat('yyyyMMdd').format(DateTime.now().toUtc());
    final dayKey = 'theory.cap.day.$userId.$date';
    final dayCount = (_prefs.getInt(dayKey) ?? 0) + 1;
    await _prefs.setInt(dayKey, dayCount);

    final now = DateTime.now().toUtc().toIso8601String();
    for (final tag in demandTags) {
      final key = 'theory.tag.last.$userId.$tag';
      await _prefs.setString(key, now);
    }
  }
}
