import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-tag cooldowns and recall history for a training session.
class PackRunSessionState {
  final String scopeKey;
  PackRunSessionState({
    this.scopeKey = 'packRunState.default',
    this.handCounter = 0,
    this.lastShownAt = -3,
    Map<String, int>? tagLastShown,
    Map<String, List<String>>? recallHistory,
    Map<String, bool>? recallShownBySpot,
    Map<String, int>? attemptsBySpot,
  })  : tagLastShown = tagLastShown ?? <String, int>{},
        recallHistory = recallHistory ?? <String, List<String>>{},
        recallShownBySpot = recallShownBySpot ?? <String, bool>{},
        attemptsBySpot = attemptsBySpot ?? <String, int>{};

  int handCounter;
  int lastShownAt;
  final Map<String, int> tagLastShown;
  final Map<String, List<String>> recallHistory;
  final Map<String, bool> recallShownBySpot;
  final Map<String, int> attemptsBySpot;

  static String keyFor({required String packId, required String sessionId}) =>
      'packRunState.$packId.$sessionId';

  Map<String, dynamic> toJson() => {
        'handCounter': handCounter,
        'tagLastShown': tagLastShown,
        'recallHistory': recallHistory,
        'recallShownBySpot': recallShownBySpot,
        'attemptsBySpot': attemptsBySpot,
        'lastShownAt': lastShownAt,
      };

  factory PackRunSessionState.fromJson(Map<String, dynamic> json,
      {required String scopeKey}) {
    return PackRunSessionState(
      scopeKey: scopeKey,
      handCounter: json['handCounter'] as int? ?? 0,
      tagLastShown: (json['tagLastShown'] as Map?)
              ?.map((key, value) => MapEntry(key as String, value as int)) ??
          <String, int>{},
      recallHistory: (json['recallHistory'] as Map?)?.map((key, value) =>
              MapEntry(key as String, (value as List).cast<String>())) ??
          <String, List<String>>{},
      recallShownBySpot: (json['recallShownBySpot'] as Map?)
              ?.map((key, value) => MapEntry(key as String, value as bool)) ??
          <String, bool>{},
      attemptsBySpot: (json['attemptsBySpot'] as Map?)
              ?.map((key, value) => MapEntry(key as String, value as int)) ??
          <String, int>{},
      lastShownAt: json['lastShownAt'] as int? ?? -3,
    );
  }

  static Future<PackRunSessionState> load(String scopeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(scopeKey);
    if (raw == null) return PackRunSessionState(scopeKey: scopeKey);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PackRunSessionState.fromJson(map, scopeKey: scopeKey);
    } catch (_) {
      return PackRunSessionState(scopeKey: scopeKey);
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(scopeKey, jsonEncode(toJson()));
  }
}
