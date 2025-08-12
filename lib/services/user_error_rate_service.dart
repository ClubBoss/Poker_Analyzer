import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

class _Entry {
  double ewma;
  int lastTs; // seconds since epoch
  int n;
  _Entry({required this.ewma, required this.lastTs, required this.n});

  Map<String, dynamic> toJson() => {
        'e': ewma,
        't': lastTs,
        'n': n,
      };

  static _Entry fromJson(Map<String, dynamic> json) => _Entry(
        ewma: (json['e'] as num).toDouble(),
        lastTs: json['t'] as int,
        n: json['n'] as int,
      );
}

class UserErrorRateService {
  UserErrorRateService._();
  static final UserErrorRateService instance = UserErrorRateService._();

  static const _prefsKey = 'user_err_rate_v1';
  final Map<String, _Entry> _data = {};
  bool _loaded = false;
  Timer? _flushTimer;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsKey);
    if (str != null) {
      final raw = jsonDecode(str) as Map<String, dynamic>;
      raw.forEach((k, v) {
        _data[k] = _Entry.fromJson(Map<String, dynamic>.from(v));
      });
    }
    _loaded = true;
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(seconds: 1), _flush);
  }

  Future<void> _flush() async {
    _flushTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _data.forEach((k, v) => map[k] = v.toJson());
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  /// Record an attempt and update EWMA for each tag.
  Future<void> recordAttempt({
    required String packId,
    required Set<String> tags,
    required bool isCorrect,
    required DateTime ts,
  }) async {
    await _ensureLoaded();
    final err = isCorrect ? 0.0 : 1.0;
    for (final tag in tags) {
      final key = '$packId|${tag.toLowerCase()}';
      final nowSec = ts.millisecondsSinceEpoch ~/ 1000;
      final entry = _data[key];
      double ewma = entry?.ewma ?? 0.0;
      int lastTs = entry?.lastTs ?? nowSec;
      int n = entry?.n ?? 0;
      final dtDays = (nowSec - lastTs) / 86400.0;
      if (dtDays > 0) {
        final decay = pow(0.5, dtDays / 7.0);
        ewma *= decay;
      }
      const alpha = 0.3;
      ewma = alpha * err + (1 - alpha) * ewma;
      ewma = ewma.clamp(0.0, 1.0);
      n += 1;
      _data[key] = _Entry(ewma: ewma, lastTs: nowSec, n: n);
      if (Random().nextInt(50) == 0) {
        AnalyticsService.instance.logEvent('user_error_rate_updated', {
          'packId': packId,
          'tag': tag,
          'ewma': ewma,
          'n': n,
        });
      }
    }
    _scheduleFlush();
  }

  /// Get error rates for given tags (lowercased). Unseen tags return 0.
  Future<Map<String, double>> getRates({
    required String packId,
    required Set<String> tags,
  }) async {
    await _ensureLoaded();
    final res = <String, double>{};
    for (final tag in tags) {
      final key = '$packId|${tag.toLowerCase()}';
      res[tag.toLowerCase()] = _data[key]?.ewma ?? 0.0;
    }
    return res;
  }

  Future<void> reset({String? packId}) async {
    await _ensureLoaded();
    if (packId == null) {
      _data.clear();
    } else {
      _data.removeWhere((key, _) => key.startsWith('$packId|'));
    }
    await _flush();
  }
}

