import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TagReviewRecord {
  final double accuracy;
  final DateTime timestamp;

  const TagReviewRecord({required this.accuracy, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TagReviewRecord.fromJson(Map<String, dynamic> json) =>
      TagReviewRecord(
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class TagReviewHistoryService {
  TagReviewHistoryService._();
  static final instance = TagReviewHistoryService._();

  static const _prefix = 'tag_review_';

  Future<void> logReview(String tag, double accuracy) async {
    final prefs = await SharedPreferences.getInstance();
    final record = TagReviewRecord(
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );
    await prefs.setString(
        '$_prefix${tag.toLowerCase()}', jsonEncode(record.toJson()));
  }

  Future<TagReviewRecord?> getRecord(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix${tag.toLowerCase()}');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return TagReviewRecord.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }
}
