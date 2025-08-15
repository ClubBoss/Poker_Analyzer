import 'dart:convert';
import 'dart:io';

class UiPrefs {
  final bool autoNext;
  final bool timeEnabled;
  final int timeLimitMs;
  final bool sound;
  const UiPrefs({
    required this.autoNext,
    required this.timeEnabled,
    required this.timeLimitMs,
    required this.sound,
  });

  Map<String, dynamic> toJson() => {
    "version": "v1",
    "autoNext": autoNext,
    "timeEnabled": timeEnabled,
    "timeLimitMs": timeLimitMs,
    "sound": sound,
  };

  static UiPrefs fromJson(Map m) {
    bool b(Object? x, bool d) => x is bool ? x : d;
    int i(Object? x, int d) => x is int ? x : (x is num ? x.toInt() : d);
    return UiPrefs(
      autoNext: b(m["autoNext"], false),
      timeEnabled: b(m["timeEnabled"], true),
      timeLimitMs: i(m["timeLimitMs"], 10000),
      sound: b(m["sound"], false),
    );
  }
}

Future<UiPrefs> loadUiPrefs({String path = 'out/ui_prefs_v1.json'}) async {
  final f = File(path);
  if (!await f.exists()) {
    return const UiPrefs(autoNext: false, timeEnabled: true, timeLimitMs: 10000, sound: false);
  }
  try {
    final root = jsonDecode(await f.readAsString());
    if (root is Map) return UiPrefs.fromJson(root);
  } catch (_) {}
  return const UiPrefs(autoNext: false, timeEnabled: true, timeLimitMs: 10000, sound: false);
}

Future<void> saveUiPrefs(UiPrefs p, {String path = 'out/ui_prefs_v1.json'}) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  final s = const JsonEncoder.withIndent('  ').convert(p.toJson());
  await f.writeAsString(s);
}
