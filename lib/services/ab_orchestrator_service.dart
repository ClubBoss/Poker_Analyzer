import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  Future<List<dynamic>> _loadSpec() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/ab_experiments.json');
    _cache = jsonDecode(raw) as List;
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
        final h = sha256.convert(utf8.encode('$userId$expId')).toString();
        final val = int.parse(h.substring(0, 8), radix: 16) / 0xFFFFFFFF;
        if (val >= traffic) {
          prefs.setString(key, '');
          continue;
        }
        final arms = (exp['arms'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
        final total =
            arms.fold<num>(0, (s, a) => s + (a['ratio'] as num? ?? 1));
        final slot = val * total;
        num cumulative = 0;
        for (final a in arms) {
          cumulative += (a['ratio'] as num? ?? 1);
          if (slot < cumulative) {
            assigned = a['id'] as String?;
            break;
          }
        }
        prefs.setString(key, assigned ?? '');
      }
      if (assigned == null || assigned.isEmpty) continue;
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
          armId: assigned!,
          prefs: prefsOv,
          audience: audienceOv,
          format: formatOv,
        ),
      );
    }
    return results;
  }

  Future<void> applyOverrides(ResolvedArm arm) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in arm.prefs.entries) {
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

