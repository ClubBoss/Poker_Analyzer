// ASCII-only; pure Dart.

import 'package:poker_analyzer/ui/session_player/models.dart';

/// Feature flag for WeaknessLog (prod default: disabled).
const bool kEnableWeaknessLog = false;

/// Internal override to enable logging in tests.
bool kEnableWeaknessLogOverride = kEnableWeaknessLog;

class WeaknessLog {
  final Map<String, int> counts = {};
  void record(String family) {
    if (!kEnableWeaknessLogOverride) return;
    counts.update(family, (v) => v + 1, ifAbsent: () => 1);
  }
}

final WeaknessLog weaknessLog = WeaknessLog();

String familyFor(SpotKind kind) {
  final n = kind.name;
  if (n.contains('jam_vs_')) return 'jam_vs_';
  if (n.contains('cbet') || n.contains('bet_')) return 'betting';
  if (n.contains('probe') || n.contains('delay')) return 'turn_control';
  if (n.contains('river')) return 'river';
  return 'misc';
}

