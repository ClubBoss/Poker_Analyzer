import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PackCompletionData {
  final DateTime completedAt;
  final int correct;
  final int total;
  final double accuracy;
  final Duration elapsed;

  bool get isPerfect => accuracy >= 1.0;

  const PackCompletionData({
    required this.completedAt,
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.elapsed,
  });

  Map<String, dynamic> toJson() => {
        'completedAt': completedAt.toIso8601String(),
        'correct': correct,
        'total': total,
        'accuracy': accuracy,
        'elapsed': elapsed.inSeconds,
      };

  factory PackCompletionData.fromJson(Map<String, dynamic> json) =>
      PackCompletionData(
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        elapsed: Duration(seconds: (json['elapsed'] as num?)?.toInt() ?? 0),
      );
}

class PackLibraryCompletionService {
  PackLibraryCompletionService._();
  static final instance = PackLibraryCompletionService._();

  static const _prefix = 'pack_progress_';

  Future<void> registerCompletion(
    String packId, {
    required int correct,
    required int total,
    Duration? elapsed,
  }) async {
    if (packId.isEmpty || total <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final accuracy = correct / total;
    final existingRaw = prefs.getString('$_prefix$packId');
    if (existingRaw != null) {
      try {
        final data = PackCompletionData.fromJson(
            jsonDecode(existingRaw) as Map<String, dynamic>);
        var should = false;
        if (now.isAfter(data.completedAt)) {
          should = true;
        } else if (now.isAtSameMomentAs(data.completedAt)) {
          should = accuracy > data.accuracy;
        } else if (accuracy > data.accuracy) {
          should = true;
        }
        if (!should) return;
      } catch (_) {}
    }
    final info = PackCompletionData(
      completedAt: now,
      correct: correct,
      total: total,
      accuracy: accuracy,
      elapsed: elapsed ?? Duration.zero,
    );
    await prefs.setString('$_prefix$packId', jsonEncode(info.toJson()));
  }

  Future<PackCompletionData?> getCompletion(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$packId');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return PackCompletionData.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, PackCompletionData>> getAllCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, PackCompletionData>{};
    for (final k in prefs.getKeys()) {
      if (k.startsWith(_prefix)) {
        final raw = prefs.getString(k);
        if (raw == null) continue;
        try {
          final data = jsonDecode(raw);
          if (data is Map) {
            final id = k.substring(_prefix.length);
            result[id] =
                PackCompletionData.fromJson(Map<String, dynamic>.from(data));
          }
        } catch (_) {}
      }
    }
    return result;
  }
}
