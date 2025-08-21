import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'autogen_pipeline_event_logger_service.dart';

class ResolvedArm {
  final String expId;
  final String armId;
  final Map<String, dynamic> prefs;
  final String? audience;
  final String? format;
  const ResolvedArm({
    required this.expId,
    required this.armId,
    this.prefs = const {},
    this.audience,
    this.format,
  });
}

class ABOrchestratorService {
  ABOrchestratorService._();
  static final ABOrchestratorService instance = ABOrchestratorService._();

  List<dynamic>? _cache;

  @visibleForTesting
  void clearCache() {
    _cache = null;
  }

  Future<List<dynamic>> _loadSpec() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/ab_experiments.json');
      _cache = jsonDecode(raw) as List;
    } catch (e) {
      AutogenPipelineEventLoggerService.log('ab_spec_error', '$e');
      _cache = const [];
    }
    return _cache!;
  }

  Future<List<ResolvedArm>> resolveActiveArms(
    String userId,
    String audience,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('ab.enabled') ?? false)) {
      return const [];
    }
    final spec = await _loadSpec();
    final results = <ResolvedArm>[];
    for (final exp in spec.cast<Map<String, dynamic>>()) {
      if (exp['active'] != true) continue;
      final expId = exp['id'] as String?;
      if (expId == null) continue;
      final audFilter = exp['audienceFilter'];
      if (audFilter != null && audFilter != audience) continue;
      final traffic = (exp['traffic'] as num?)?.toDouble() ?? 0.0;
      final key = 'ab.assignment.$expId.$userId';
      var assigned = prefs.getString(key);
      if (assigned == null) {
        final h1 = sha256.convert(utf8.encode('$userId|$expId')).toString();
        final u1 = int.parse(h1.substring(0, 8), radix: 16) / 0xFFFFFFFF;
        if (u1 >= traffic) {
          assigned = 'none';
          await prefs.setString(key, assigned);
          final cKey = 'ab.assignments.$expId.$assigned.n';
          await prefs.setInt(cKey, (prefs.getInt(cKey) ?? 0) + 1);
          continue;
        }
        final arms =
            (exp['arms'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        final h2 = sha256.convert(utf8.encode('$userId|$expId|arm')).toString();
        final u2 = int.parse(h2.substring(0, 8), radix: 16) / 0xFFFFFFFF;
        final total = arms.fold<num>(
          0,
          (s, a) => s + (a['ratio'] as num? ?? 1),
        );
        final slot = u2 * total;
        num cumulative = 0;
        for (final a in arms) {
          cumulative += (a['ratio'] as num? ?? 1);
          if (slot < cumulative) {
            assigned = a['id'] as String? ?? 'control';
            break;
          }
        }
        assigned ??= 'control';
        await prefs.setString(key, assigned);
        final cKey = 'ab.assignments.$expId.$assigned.n';
        await prefs.setInt(cKey, (prefs.getInt(cKey) ?? 0) + 1);
      }
      if (assigned == 'none') continue;
      final armSpec = (exp['arms'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((a) => a['id'] == assigned, orElse: () => {});
      final overrides = armSpec['overrides'] as Map<String, dynamic>? ?? {};
      final prefsOv = (overrides['prefs'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          const {};
      final audienceOv = overrides['audience.level'] as String?;
      final formatOv = overrides['session.format'] as String?;
      results.add(
        ResolvedArm(
          expId: expId,
          armId: assigned,
          prefs: prefsOv,
          audience: audienceOv,
          format: formatOv,
        ),
      );
    }
    return results;
  }

  Future<T> withOverrides<T>(ResolvedArm arm, Future<T> Function() fn) async {
    final prefs = await SharedPreferences.getInstance();
    final original = <String, Object?>{};
    final missing = <String>{};
    for (final entry in arm.prefs.entries) {
      final k = entry.key;
      if (prefs.containsKey(k)) {
        original[k] = prefs.get(k);
      } else {
        missing.add(k);
      }
      final v = entry.value;
      if (v is int) {
        await prefs.setInt(k, v);
      } else if (v is double) {
        await prefs.setDouble(k, v);
      } else if (v is bool) {
        await prefs.setBool(k, v);
      } else if (v is String) {
        await prefs.setString(k, v);
      }
    }
    try {
      return await fn();
    } finally {
      for (final k in missing) {
        await prefs.remove(k);
      }
      for (final entry in original.entries) {
        final k = entry.key;
        final v = entry.value;
        if (v is int) {
          await prefs.setInt(k, v);
        } else if (v is double) {
          await prefs.setDouble(k, v);
        } else if (v is bool) {
          await prefs.setBool(k, v);
        } else if (v is String) {
          await prefs.setString(k, v);
        }
      }
    }
  }

  void logExposure(
    String userId,
    String expId,
    String armId, {
    required String audience,
    required String format,
  }) {
    AutogenPipelineEventLoggerService.log(
      'ab_exposure',
      jsonEncode({
        'userId': userId,
        'expId': expId,
        'armId': armId,
        'audience': audience,
        'format': format,
      }),
    );
  }
}
