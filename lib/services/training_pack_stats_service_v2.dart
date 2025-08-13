import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_stats_service.dart';

class PackResultEntry {
  final String packId;
  final double completion;
  final double evLoss;
  final double accuracy;
  final DateTime timestamp;
  final String type;
  final String? tag;
  final String? cluster;

  const PackResultEntry({
    required this.packId,
    required this.completion,
    required this.evLoss,
    required this.accuracy,
    required this.timestamp,
    required this.type,
    this.tag,
    this.cluster,
  });

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'completion': completion,
        'evLoss': evLoss,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        if (tag != null) 'tag': tag,
        if (cluster != null) 'cluster': cluster,
      };

  factory PackResultEntry.fromJson(Map<String, dynamic> j) => PackResultEntry(
        packId: j['packId'] as String? ?? '',
        completion: (j['completion'] as num?)?.toDouble() ?? 0,
        evLoss: (j['evLoss'] as num?)?.toDouble() ?? 0,
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
        type: j['type'] as String? ?? 'regular',
        tag: j['tag'] as String?,
        cluster: j['cluster'] as String?,
      );
}

class TrainingPackStatsServiceV2 {
  static const _key = 'training_pack_stats_v2';

  static Future<List<PackResultEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map) PackResultEntry.fromJson(Map<String, dynamic>.from(e))
        ];
      }
    } catch (_) {}
    return [];
  }

  static Future<void> _save(List<PackResultEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in list) e.toJson()]));
  }

  static Future<void> recordPackResult(
    TrainingPackTemplateV2 pack,
    double accuracy,
    double avgEvLoss, {
    DateTime? now,
  }) async {
    final time = now ?? DateTime.now();
    final completed = await TrainingPackStatsService.getHandsCompleted(pack.id);
    final total = pack.spots.isNotEmpty ? pack.spots.length : pack.spotCount;
    final completion = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final type = (pack.meta['type'] as String?) ?? 'regular';
    final tag = pack.meta['tag']?.toString();
    final cluster = pack.meta['cluster']?.toString();
    final entry = PackResultEntry(
      packId: pack.id,
      completion: completion,
      evLoss: avgEvLoss,
      accuracy: accuracy,
      timestamp: time,
      type: type,
      tag: tag,
      cluster: cluster,
    );
    final list = await _load();
    list.add(entry);
    while (list.length > 100) {
      list.removeAt(0);
    }
    await _save(list);
  }

  static Future<Map<String, double>> improvementByTag() async {
    final list = await _load();
    final Map<String, List<PackResultEntry>> byTag = {};
    for (final e in list) {
      final key = e.tag ?? e.cluster;
      if (key == null || key.isEmpty) continue;
      (byTag[key] ??= []).add(e);
    }
    final result = <String, double>{};
    for (final entry in byTag.entries) {
      final records = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (records.length < 2) continue;
      final first = records.first.accuracy;
      final last = records.last.accuracy;
      result[entry.key] = last - first;
    }
    return result;
  }
}
