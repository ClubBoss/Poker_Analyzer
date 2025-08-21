import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_run_record.dart';

class ABArmResult {
  final String armId;
  final int n;
  final double accuracy;
  final double dropoffRate;
  final double timeToComplete;
  final double novelty;
  final double compositeScore;
  final double confidence;

  const ABArmResult({
    required this.armId,
    required this.n,
    required this.accuracy,
    required this.dropoffRate,
    required this.timeToComplete,
    required this.novelty,
    required this.compositeScore,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'armId': armId,
    'n': n,
    'accuracy': accuracy,
    'dropoffRate': dropoffRate,
    'timeToComplete': timeToComplete,
    'novelty': novelty,
    'compositeScore': compositeScore,
    'confidence': confidence,
  };
}

class TrainingRunABComparator {
  static const _armsKey = 'ab.experiment_arms';
  static const _reportKey = 'ab.last_report';
  static const _recommendedKey = 'ab.recommended_format';
  static const _weightsKey = 'ab.metric_weights';
  static const _controlKey = 'ab.control_arm';

  Future<List<ABArmResult>> compare(
    List<TrainingRunRecord> runs, {
    String? audience,
  }) async {
    if (runs.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final armsConfig = await _loadArms(prefs);
    final filtered = audience == null
        ? runs
        : runs.where((r) => r.audience == audience).toList();
    if (filtered.isEmpty) return [];

    final grouped = <String, List<TrainingRunRecord>>{};
    for (final r in filtered) {
      grouped.putIfAbsent(r.armId, () => []).add(r);
    }

    final stats = <String, _ArmStats>{};
    for (final e in grouped.entries) {
      stats[e.key] = _computeStats(e.value);
    }

    final means = _MetricAverages.from(stats.values);
    final stds = _MetricStd.from(stats.values, means);
    final weights = _loadWeights(prefs);

    final results = <ABArmResult>[];
    for (final entry in stats.entries) {
      final id = entry.key;
      final s = entry.value;
      final accZ = _zScore(s.accuracy, means.accuracy, stds.accuracy);
      final dropZ = -_zScore(s.dropoff, means.dropoff, stds.dropoff);
      final timeZ = -_zScore(s.time, means.time, stds.time);
      final noveltyZ = _zScore(s.novelty, means.novelty, stds.novelty);
      final composite =
          weights['accuracy']! * accZ +
          weights['dropoff']! * dropZ +
          weights['time']! * timeZ +
          weights['novelty']! * noveltyZ;
      final confidence = s.n / (s.n + 10);
      results.add(
        ABArmResult(
          armId: id,
          n: s.n,
          accuracy: s.accuracy,
          dropoffRate: s.dropoff,
          timeToComplete: s.time,
          novelty: s.novelty,
          compositeScore: composite,
          confidence: confidence,
        ),
      );
    }
    results.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    await prefs.setString(
      _reportKey,
      jsonEncode(results.map((e) => e.toJson()).toList()),
    );
    if (results.isNotEmpty) {
      final best = results.first;
      final arm = armsConfig.firstWhere(
        (a) => a['id'] == best.armId,
        orElse: () => null,
      );
      await prefs.setString(_recommendedKey, jsonEncode(arm['format'] ?? {}));
    }
    return results;
  }

  Future<ABArmResult?> best(
    List<TrainingRunRecord> runs, {
    String? audience,
  }) async {
    final results = await compare(runs, audience: audience);
    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> _loadArms(SharedPreferences prefs) async {
    final raw = prefs.getString(_armsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return const [];
  }

  Map<String, double> _loadWeights(SharedPreferences prefs) {
    const def = {
      'accuracy': 0.4,
      'dropoff': 0.25,
      'time': 0.2,
      'novelty': 0.15,
    };
    final raw = prefs.getString(_weightsKey);
    if (raw == null) return def;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return {
          'accuracy':
              (data['accuracy'] as num?)?.toDouble() ?? def['accuracy']!,
          'dropoff': (data['dropoff'] as num?)?.toDouble() ?? def['dropoff']!,
          'time': (data['time'] as num?)?.toDouble() ?? def['time']!,
          'novelty': (data['novelty'] as num?)?.toDouble() ?? def['novelty']!,
        };
      }
    } catch (_) {}
    return def;
  }

  Future<void> saveWeights(Map<String, double> w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightsKey, jsonEncode(w));
  }

  Future<Map<String, double>> getWeights() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadWeights(prefs);
  }

  Future<void> saveControlArm(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_controlKey, id);
  }

  Future<String?> getControlArm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_controlKey);
  }

  double _zScore(double value, double mean, double std) {
    if (std == 0) return 0;
    return (value - mean) / std;
  }
}

class _ArmStats {
  final int n;
  final double accuracy;
  final double dropoff;
  final double time;
  final double novelty;

  _ArmStats({
    required this.n,
    required this.accuracy,
    required this.dropoff,
    required this.time,
    required this.novelty,
  });
}

_ArmStats _computeStats(List<TrainingRunRecord> list) {
  final n = list.length;
  double avg(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
  return _ArmStats(
    n: n,
    accuracy: avg(list.map((e) => e.accuracy).toList()),
    dropoff: avg(list.map((e) => e.dropoffRate).toList()),
    time: avg(list.map((e) => e.timeToComplete).toList()),
    novelty: avg(list.map((e) => e.novelty).toList()),
  );
}

class _MetricAverages {
  final double accuracy;
  final double dropoff;
  final double time;
  final double novelty;

  _MetricAverages({
    required this.accuracy,
    required this.dropoff,
    required this.time,
    required this.novelty,
  });

  factory _MetricAverages.from(Iterable<_ArmStats> stats) {
    double avg(Iterable<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    return _MetricAverages(
      accuracy: avg(stats.map((e) => e.accuracy)),
      dropoff: avg(stats.map((e) => e.dropoff)),
      time: avg(stats.map((e) => e.time)),
      novelty: avg(stats.map((e) => e.novelty)),
    );
  }
}

class _MetricStd {
  final double accuracy;
  final double dropoff;
  final double time;
  final double novelty;

  _MetricStd({
    required this.accuracy,
    required this.dropoff,
    required this.time,
    required this.novelty,
  });

  factory _MetricStd.from(Iterable<_ArmStats> stats, _MetricAverages means) {
    double variance(Iterable<double> xs, double mean) {
      if (xs.isEmpty) return 0;
      final v =
          xs.map((e) => pow(e - mean, 2)).reduce((a, b) => a + b) / xs.length;
      return sqrt(v);
    }

    return _MetricStd(
      accuracy: variance(stats.map((e) => e.accuracy), means.accuracy),
      dropoff: variance(stats.map((e) => e.dropoff), means.dropoff),
      time: variance(stats.map((e) => e.time), means.time),
      novelty: variance(stats.map((e) => e.novelty), means.novelty),
    );
  }
}
