import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'decay_tag_retention_tracker_service.dart';

class TagSkill {
  final double mastery;
  final double confidence;
  final DateTime lastSeen;
  final int seenCount;

  TagSkill({
    required this.mastery,
    required this.confidence,
    required this.lastSeen,
    required this.seenCount,
  });

  TagSkill copyWith({
    double? mastery,
    double? confidence,
    DateTime? lastSeen,
    int? seenCount,
  }) => TagSkill(
    mastery: mastery ?? this.mastery,
    confidence: confidence ?? this.confidence,
    lastSeen: lastSeen ?? this.lastSeen,
    seenCount: seenCount ?? this.seenCount,
  );

  Map<String, dynamic> toJson() => {
    'mastery': mastery,
    'confidence': confidence,
    'lastSeen': lastSeen.toIso8601String(),
    'seenCount': seenCount,
  };

  static TagSkill fromJson(Map<String, dynamic> json) => TagSkill(
    mastery: (json['mastery'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    lastSeen: DateTime.parse(json['lastSeen'] as String),
    seenCount: json['seenCount'] as int,
  );
}

class UserSkillModelService {
  UserSkillModelService._();
  static final UserSkillModelService instance = UserSkillModelService._();

  static const _prefix = 'skillModel.';

  Future<Map<String, TagSkill>> getSkills(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw) as Map;
      return data.map(
        (k, v) => MapEntry(
          k as String,
          TagSkill.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(String userId, Map<String, TagSkill> skills) async {
    final prefs = await SharedPreferences.getInstance();
    final data = skills.map((k, v) => MapEntry(k, v.toJson()));
    final json = jsonEncode(data);
    // safe write with temp key then swap
    await prefs.setString('$_prefix$userId.tmp', json);
    await prefs.setString('$_prefix$userId', json);
  }

  Future<void> recordAttempt(
    String userId,
    List<String> tags, {
    required bool correct,
  }) async {
    final skills = await getSkills(userId);
    final now = DateTime.now();
    for (final t in tags) {
      final tag = t.toLowerCase();
      final existing = skills[tag];
      final mastery = existing?.mastery ?? 0.5;
      final confidence = existing?.confidence ?? 0.0;
      final seen = existing?.seenCount ?? 0;
      final result = correct ? 1.0 : 0.0;
      final alpha = (0.4 / sqrt(seen + 1)).clamp(0.02, 0.25);
      final mPrime = (1 - alpha) * mastery + alpha * result;
      const gamma = 0.02;
      const delta = 0.002;
      const epsilon = 0.15;
      final confPrime =
          (confidence +
                  ((result - mPrime).abs() < epsilon ? gamma : 0.0) -
                  delta)
              .clamp(0.0, 1.0);
      skills[tag] = TagSkill(
        mastery: mPrime,
        confidence: confPrime,
        lastSeen: now,
        seenCount: seen + 1,
      );
    }
    await _save(userId, skills);
  }

  Future<void> decayTick(String userId) async {
    final skills = await getSkills(userId);
    if (skills.isEmpty) return;
    final now = DateTime.now();
    var changed = false;
    const startDays = 7;
    const rate = 0.01;
    final retention = const DecayTagRetentionTrackerService();
    skills.forEach((tag, skill) {
      final days = now.difference(skill.lastSeen).inDays;
      if (days > startDays) {
        final decay = (days - startDays) * rate;
        final newMastery = (skill.mastery * (1 - decay)).clamp(0.0, 1.0);
        if (newMastery != skill.mastery) {
          skills[tag] = skill.copyWith(mastery: newMastery);
          changed = true;
          retention.notifyDecayStateChanged(tag);
        }
      }
    });
    if (changed) await _save(userId, skills);
  }
}
