import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/injected_path_module.dart';

class OutcomeStats {
  final int n;
  final double meanDelta;
  final double varDelta;
  const OutcomeStats({required this.n, required this.meanDelta, required this.varDelta});
}

class AdaptiveOutcomeTracker {
  AdaptiveOutcomeTracker._();
  static final AdaptiveOutcomeTracker instance = AdaptiveOutcomeTracker._();

  static const _prefix = 'adaptive.outcomes.';

  Future<Map<String, dynamic>> _load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$userId', jsonEncode(data));
  }

  Future<void> onModuleStarted(String userId, InjectedPathModule m) async {
    final prefs = await SharedPreferences.getInstance();
    final window = prefs.getInt('adaptive.baseline.window') ?? 5;
    final data = await _load(userId);
    final tags = (m.metrics['clusterTags'] as List?)?.cast<String>() ?? const [];
    final baseline = _estimateBaseline(data, tags, window);
    data[m.moduleId] = {
      'startedAt': DateTime.now().toIso8601String(),
      'baselinePass': baseline,
      'tags': tags,
    };
    await _save(userId, data);
  }

  double _estimateBaseline(
      Map<String, dynamic> data, List<String> tags, int window) {
    final records = data.values.whereType<Map>().toList();
    records.sort((a, b) {
      final aT = DateTime.tryParse(a['completedAt'] ?? '') ?? DateTime(0);
      final bT = DateTime.tryParse(b['completedAt'] ?? '') ?? DateTime(0);
      return bT.compareTo(aT);
    });
    final rates = <double>[];
    for (final r in records) {
      if (rates.length >= window) break;
      final rTags = (r['tags'] as List?)?.cast<String>() ?? const [];
      if (!rTags.any(tags.contains)) continue;
      final pr = (r['passRate'] as num?)?.toDouble();
      if (pr != null) rates.add(pr.clamp(0.0, 1.0));
    }
    if (rates.isEmpty) return 0.5;
    final sum = rates.reduce((a, b) => a + b);
    return (sum / rates.length).clamp(0.0, 1.0);
  }

  Future<Map<String, double>> onModuleCompleted(
    String userId,
    InjectedPathModule m, {
    required double passRate,
  }) async {
    final data = await _load(userId);
    final rec = Map<String, dynamic>.from(data[m.moduleId] ?? {});
    final tags = (rec['tags'] as List?)?.cast<String>() ??
        (m.metrics['clusterTags'] as List?)?.cast<String>() ??
        const [];
    final base = (rec['baselinePass'] as num?)?.toDouble() ?? 0.5;
    final pr = passRate.clamp(0.0, 1.0);
    var delta = (pr - base.clamp(0.0, 1.0)).clamp(-1.0, 1.0);
    final perTag = <String, double>{};
    if (tags.isNotEmpty) {
      final share = delta / tags.length;
      for (final t in tags) {
        perTag[t] = share;
      }
    }
    data[m.moduleId] = {
      'startedAt': rec['startedAt'],
      'baselinePass': base.clamp(0.0, 1.0),
      'completedAt': DateTime.now().toIso8601String(),
      'passRate': pr,
      'tags': tags,
    };
    await _save(userId, data);

    final ab = m.metrics['abArm'] as String?;
    if (ab != null && ab.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final pairs = ab.split(',');
      for (final p in pairs) {
        final parts = p.split(':');
        if (parts.length != 2) continue;
        final key = 'ab.outcomes.${parts[0]}.${parts[1]}';
        final n = prefs.getInt('$key.n') ?? 0;
        final mean = prefs.getDouble('$key.mean') ?? 0.0;
        final newMean = (mean * n + delta) / (n + 1);
        await prefs.setInt('$key.n', n + 1);
        await prefs.setDouble('$key.mean', newMean);
      }
    }
    return perTag;
  }

  Future<OutcomeStats> getTagStats(String userId, String tag) async {
    final data = await _load(userId);
    int n = 0;
    double mean = 0.0, m2 = 0.0;
    for (final rec in data.values.whereType<Map>()) {
      if (rec['completedAt'] == null) continue;
      final tags = (rec['tags'] as List?)?.cast<String>() ?? const [];
      if (!tags.contains(tag)) continue;
      final pass = (rec['passRate'] as num?)?.toDouble();
      final base = (rec['baselinePass'] as num?)?.toDouble();
      if (pass == null || base == null) continue;
      final delta = (pass.clamp(0.0, 1.0) - base.clamp(0.0, 1.0))
          .clamp(-1.0, 1.0) /
          tags.length;
      n++;
      final diff = delta - mean;
      mean += diff / n;
      m2 += diff * (delta - mean);
    }
    final varDelta = n > 1 ? m2 / (n - 1) : 0.0;
    return OutcomeStats(n: n, meanDelta: mean, varDelta: varDelta);
  }
}
