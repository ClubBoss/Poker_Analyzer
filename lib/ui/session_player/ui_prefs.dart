import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class UiPrefs {
  final bool autoNext;
  final bool timeEnabled;
  final int timeLimitMs;
  final bool sound;
  final bool autoWhyOnWrong;
  final int autoNextDelayMs;
  const UiPrefs({
    required this.autoNext,
    required this.timeEnabled,
    required this.timeLimitMs,
    required this.sound,
    required this.autoWhyOnWrong,
    required this.autoNextDelayMs,
  });

  Map<String, dynamic> toJson() => {
    "version": "v1",
    "autoNext": autoNext,
    "timeEnabled": timeEnabled,
    "timeLimitMs": timeLimitMs,
    "sound": sound,
    "autoWhyOnWrong": autoWhyOnWrong,
  };

  static UiPrefs fromJson(Map m, {required int autoNextDelayMs}) {
    bool b(Object? x, bool d) => x is bool ? x : d;
    int i(Object? x, int d) => x is int ? x : (x is num ? x.toInt() : d);
    return UiPrefs(
      autoNext: b(m["autoNext"], false),
      timeEnabled: b(m["timeEnabled"], true),
      timeLimitMs: i(m["timeLimitMs"], 10000),
      sound: b(m["sound"], false),
      autoWhyOnWrong:
          b(m["autoWhyOnWrong"], b(m["autoExplainOnWrong"], true)),
      autoNextDelayMs: autoNextDelayMs,
    );
  }
}

Future<UiPrefs> loadUiPrefs({String path = 'out/ui_prefs_v1.json'}) async {
  final prefs = await SharedPreferences.getInstance();
  final delay = (prefs.getInt('ui_auto_next_delay_ms') ?? 600).clamp(300, 800);
  final f = File(path);
  if (!await f.exists()) {
    return UiPrefs(
        autoNext: false,
        timeEnabled: true,
        timeLimitMs: 10000,
        sound: false,
        autoWhyOnWrong: true,
        autoNextDelayMs: delay as int);
  }
  try {
    final root = jsonDecode(await f.readAsString());
    if (root is Map) return UiPrefs.fromJson(root, autoNextDelayMs: delay as int);
  } catch (_) {}
  return UiPrefs(
      autoNext: false,
      timeEnabled: true,
      timeLimitMs: 10000,
      sound: false,
      autoWhyOnWrong: true,
      autoNextDelayMs: delay as int);
}

Future<void> saveUiPrefs(UiPrefs p, {String path = 'out/ui_prefs_v1.json'}) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  final s = const JsonEncoder.withIndent('  ').convert(p.toJson());
  await f.writeAsString(s);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('ui_auto_next_delay_ms',
      (p.autoNextDelayMs).clamp(300, 800) as int);
}
