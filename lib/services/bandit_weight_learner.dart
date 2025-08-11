import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class BanditWeightLearner {
  BanditWeightLearner._();
  static final BanditWeightLearner instance = BanditWeightLearner._();

  Future<void> updateFromOutcome(
      String userId, Map<String, double> tagDeltas) async {
    final prefs = await SharedPreferences.getInstance();
    final scale = prefs.getDouble('bandit.deltaScale') ?? 0.1;
    final maxVal = prefs.getDouble('bandit.maxAlphaBeta') ?? 10000;
    for (final e in tagDeltas.entries) {
      final tag = e.key;
      final d = e.value.clamp(-1.0, 1.0);
      final p = 1 / (1 + exp(-d / scale));
      final aKey = 'bandit.alpha.$userId.$tag';
      final bKey = 'bandit.beta.$userId.$tag';
      var a = prefs.getDouble(aKey) ?? 1.0;
      var b = prefs.getDouble(bKey) ?? 1.0;
      a = (a + p).clamp(1.0, maxVal);
      b = (b + (1 - p)).clamp(1.0, maxVal);
      await prefs.setDouble(aKey, a);
      await prefs.setDouble(bKey, b);
    }
  }

  Future<double> getImpact(String userId, String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getDouble('bandit.alpha.$userId.$tag') ?? 1.0;
    final b = prefs.getDouble('bandit.beta.$userId.$tag') ?? 1.0;
    final mean = a / (a + b);
    var impact = 1.0 + 0.8 * (mean - 0.5);
    impact = impact.clamp(0.5, 2.0);
    final threshold = prefs.getDouble('bandit.optimismThreshold') ?? 10;
    if (a + b < threshold) impact += 0.05;
    return impact.clamp(0.5, 2.0);
  }

  Future<Map<String, double>> getAllImpacts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final aPrefix = 'bandit.alpha.$userId.';
    final bPrefix = 'bandit.beta.$userId.';
    final tags = <String>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(aPrefix)) {
        tags.add(key.substring(aPrefix.length));
      } else if (key.startsWith(bPrefix)) {
        tags.add(key.substring(bPrefix.length));
      }
    }
    final result = <String, double>{};
    for (final t in tags) {
      final a = prefs.getDouble('bandit.alpha.$userId.$t') ?? 1.0;
      final b = prefs.getDouble('bandit.beta.$userId.$t') ?? 1.0;
      final mean = a / (a + b);
      var impact = 1.0 + 0.8 * (mean - 0.5);
      impact = impact.clamp(0.5, 2.0);
      final threshold = prefs.getDouble('bandit.optimismThreshold') ?? 10;
      if (a + b < threshold) impact += 0.05;
      result[t] = impact.clamp(0.5, 2.0);
    }
    return result;
  }
}
