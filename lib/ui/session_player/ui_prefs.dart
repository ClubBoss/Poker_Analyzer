import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class UiPrefs {
  final bool autoNext;
  final bool timeEnabled;
  final int timeLimitMs;
  final bool sound;
  final bool haptics;
  final bool autoWhyOnWrong;
  final int autoNextDelayMs;
  final double fontScale;
  const UiPrefs({
    required this.autoNext,
    required this.timeEnabled,
    required this.timeLimitMs,
    required this.sound,
    required this.haptics,
    required this.autoWhyOnWrong,
    required this.autoNextDelayMs,
    required this.fontScale,
  });

  Map<String, dynamic> toJson() => {
    "version": "v1",
    "autoNext": autoNext,
    "timeEnabled": timeEnabled,
    "timeLimitMs": timeLimitMs,
    "sound": sound,
    "haptics": haptics,
    "autoWhyOnWrong": autoWhyOnWrong,
    "fontScale": fontScale,
  };

  static UiPrefs fromJson(Map m, {required int autoNextDelayMs}) {
    bool b(Object? x, bool d) => x is bool ? x : d;
    int i(Object? x, int d) => x is int ? x : (x is num ? x.toInt() : d);
    double d(Object? x, double dflt) => x is num ? x.toDouble() : dflt;
    final fs = d(m["fontScale"], 1.0).clamp(0.9, 1.3);
    return UiPrefs(
      autoNext: b(m["autoNext"], false),
      timeEnabled: b(m["timeEnabled"], true),
      timeLimitMs: i(m["timeLimitMs"], 10000),
      sound: b(m["sound"], false),
      haptics: b(m["haptics"], true),
      autoWhyOnWrong: b(m["autoWhyOnWrong"], b(m["autoExplainOnWrong"], false)),
      autoNextDelayMs: autoNextDelayMs,
      fontScale: fs,
    );
  }
}

Future<UiPrefs> loadUiPrefs({String path = 'out/ui_prefs_v1.json'}) async {
  final prefs = await SharedPreferences.getInstance();
  final delay = (prefs.getInt('ui_auto_next_delay_ms') ?? 600).clamp(300, 800);
  final fsOverride = prefs.getDouble('ui_font_scale');
  final f = File(path);
  if (!await f.exists()) {
    return UiPrefs(
      autoNext: false,
      timeEnabled: true,
      timeLimitMs: 10000,
      sound: false,
      haptics: true,
      autoWhyOnWrong: false,
      autoNextDelayMs: delay,
      fontScale: (fsOverride ?? 1.0).clamp(0.9, 1.3),
    );
  }
  try {
    final root = jsonDecode(await f.readAsString());
    if (root is Map) {
      var p = UiPrefs.fromJson(root, autoNextDelayMs: delay);
      final fs = (fsOverride ?? p.fontScale).clamp(0.9, 1.3);
      p = UiPrefs(
        autoNext: p.autoNext,
        timeEnabled: p.timeEnabled,
        timeLimitMs: p.timeLimitMs,
        sound: p.sound,
        haptics: p.haptics,
        autoWhyOnWrong: p.autoWhyOnWrong,
        autoNextDelayMs: p.autoNextDelayMs,
        fontScale: fs,
      );
      return p;
    }
  } catch (_) {}
  return UiPrefs(
    autoNext: false,
    timeEnabled: true,
    timeLimitMs: 10000,
    sound: false,
    haptics: true,
    autoWhyOnWrong: false,
    autoNextDelayMs: delay,
    fontScale: (fsOverride ?? 1.0).clamp(0.9, 1.3),
  );
}

Future<void> saveUiPrefs(
  UiPrefs p, {
  String path = 'out/ui_prefs_v1.json',
}) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  final s = const JsonEncoder.withIndent('  ').convert(p.toJson());
  await f.writeAsString(s);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    'ui_auto_next_delay_ms',
    (p.autoNextDelayMs).clamp(300, 800),
  );
  await prefs.setDouble('ui_font_scale', (p.fontScale).clamp(0.9, 1.3));
}
