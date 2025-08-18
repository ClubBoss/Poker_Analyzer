import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TagMasteryAdjustmentEntry {
  final String tag;
  final double delta;
  final DateTime timestamp;

  const TagMasteryAdjustmentEntry({
    required this.tag,
    required this.delta,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'delta': delta,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TagMasteryAdjustmentEntry.fromJson(Map<String, dynamic> json) =>
      TagMasteryAdjustmentEntry(
        tag: json['tag'] as String? ?? '',
        delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Persists mastery adjustment logs for debugging.
class TagMasteryAdjustmentLogService {
  static const _key = 'tag_mastery_adjust_logs';
  TagMasteryAdjustmentLogService._();
  static final instance = TagMasteryAdjustmentLogService._();

  final List<TagMasteryAdjustmentEntry> _logs = [];

  List<TagMasteryAdjustmentEntry> get logs => List.unmodifiable(_logs);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        _logs
          ..clear()
          ..addAll(
            data.map(
              (e) => TagMasteryAdjustmentEntry.fromJson(
                Map<String, dynamic>.from(e),
              ),
            ),
          );
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final l in _logs) l.toJson()]),
    );
  }

  Future<void> add(TagMasteryAdjustmentEntry entry) async {
    _logs.insert(0, entry);
    while (_logs.length > 100) {
      _logs.removeLast();
    }
    await _save();
  }
}
