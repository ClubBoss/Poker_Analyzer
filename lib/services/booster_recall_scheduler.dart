import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'booster_completion_tracker.dart';

/// Schedules skipped boosters to be re-surfaced in future stages.
class BoosterRecallScheduler {
  BoosterRecallScheduler._();
  static final BoosterRecallScheduler instance = BoosterRecallScheduler._();

  static const String _prefsKey = 'booster_recall_scheduler';

  final Map<String, _MissRecord> _missed = <String, _MissRecord>{};
  final Map<String, Set<String>> _reinjected = <String, Set<String>>{};
  bool _loaded = false;

  /// Clears cached data for tests.
  void resetForTest() {
    _loaded = false;
    _missed.clear();
    _reinjected.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          for (final e in data.entries) {
            final record = _MissRecord.fromJson(
              Map<String, dynamic>.from(e.value),
            );
            _missed[e.key.toString()] = record;
          }
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _missed.entries) e.key: e.value.toJson()}),
    );
  }

  void _applyDecay() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toRemove = <String>[];
    _missed.forEach((key, record) {
      if (record.lastMiss.isBefore(cutoff)) {
        final decayed = record.count - 1;
        if (decayed <= 0) {
          toRemove.add(key);
        } else {
          _missed[key] = record.copyWith(count: decayed, lastMiss: cutoff);
        }
      }
    });
    for (final k in toRemove) {
      _missed.remove(k);
    }
  }

  /// Applies decay to stored records and persists changes.
  Future<void> applyDecay() async {
    await _load();
    _applyDecay();
    await _save();
  }

  /// Records that [boosterId] was skipped.
  Future<void> markBoosterSkipped(String boosterId) async {
    if (boosterId.isEmpty) return;
    await _load();
    final record = _missed[boosterId];
    if (record == null) {
      _missed[boosterId] = _MissRecord(1, DateTime.now());
    } else {
      _missed[boosterId] = record.copyWith(
        count: record.count + 1,
        lastMiss: DateTime.now(),
      );
    }
    await _save();
  }

  /// Returns booster ids sorted by missed count for [stageId].
  Future<List<String>> getDueBoosters(String stageId, {int limit = 2}) async {
    await _load();
    _applyDecay();
    final shown = _reinjected[stageId] ?? <String>{};
    final entries = _missed.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final result = <String>[];
    for (final e in entries) {
      if (result.length >= limit) break;
      if (shown.contains(e.key)) continue;
      if (await BoosterCompletionTracker.instance.isBoosterCompleted(e.key)) {
        continue;
      }
      result.add(e.key);
      shown.add(e.key);
    }
    if (result.isNotEmpty) {
      _reinjected[stageId] = shown;
    }
    await _save();
    return result;
  }

  /// Clears reinjection history for [stageId].
  void clearStage(String stageId) {
    _reinjected.remove(stageId);
  }
}

class _MissRecord {
  final int count;
  final DateTime lastMiss;

  const _MissRecord(this.count, this.lastMiss);

  _MissRecord copyWith({int? count, DateTime? lastMiss}) {
    return _MissRecord(count ?? this.count, lastMiss ?? this.lastMiss);
  }

  Map<String, dynamic> toJson() => {
        'c': count,
        't': lastMiss.toIso8601String(),
      };

  factory _MissRecord.fromJson(Map<String, dynamic> json) => _MissRecord(
        json['c'] as int? ?? 0,
        DateTime.tryParse(json['t'] as String? ?? '') ?? DateTime.now(),
      );
}
