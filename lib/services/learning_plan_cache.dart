import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/learning_goal.dart';
import '../models/training_track.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'adaptive_learning_flow_engine.dart';

/// Persists the last generated [AdaptiveLearningPlan] to allow instant resume
/// after app restart.
class LearningPlanCache {
  static const _key = 'learning_plan_cache';

  const LearningPlanCache();

  /// Saves [plan] to local storage.
  Future<void> save(AdaptiveLearningPlan plan) async {
    final prefs = await PreferencesService.getInstance();
    final data = _planToJson(plan);
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Loads cached plan if available. Returns `null` if the cache is missing
  /// or corrupted.
  Future<AdaptiveLearningPlan?> load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return _planFromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _planToJson(AdaptiveLearningPlan plan) => {
        'goals': [for (final g in plan.goals) _goalToJson(g)],
        'tracks': [for (final t in plan.recommendedTracks) _trackToJson(t)],
        if (plan.mistakeReplayPack != null)
          'mistakePack': plan.mistakeReplayPack!.toJson(),
      };

  Map<String, dynamic> _goalToJson(LearningGoal g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'tag': g.tag,
        'priority': g.priorityScore,
      };

  Map<String, dynamic> _trackToJson(TrainingTrack t) => {
        'id': t.id,
        'title': t.title,
        'goalId': t.goalId,
        'tags': t.tags,
        'spots': [for (final s in t.spots) s.toJson()],
      };

  AdaptiveLearningPlan? _planFromJson(Map<String, dynamic> j) {
    final goalsRaw = j['goals'];
    final tracksRaw = j['tracks'];
    if (goalsRaw is! List || tracksRaw is! List) return null;

    final goals = <LearningGoal>[];
    for (final g in goalsRaw) {
      if (g is! Map) return null;
      goals.add(LearningGoal(
        id: g['id'] as String? ?? '',
        title: g['title'] as String? ?? '',
        description: g['description'] as String? ?? '',
        tag: g['tag'] as String? ?? '',
        priorityScore: (g['priority'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    final tracks = <TrainingTrack>[];
    for (final t in tracksRaw) {
      if (t is! Map) return null;
      final spotsRaw = t['spots'];
      if (spotsRaw is! List) return null;
      final spots = <TrainingPackSpot>[];
      for (final s in spotsRaw) {
        if (s is! Map) return null;
        spots.add(
            TrainingPackSpot.fromJson(Map<String, dynamic>.from(s)));
      }
      tracks.add(TrainingTrack(
        id: t['id'] as String? ?? '',
        title: t['title'] as String? ?? '',
        goalId: t['goalId'] as String? ?? '',
        spots: spots,
        tags: [for (final tag in (t['tags'] as List? ?? [])) tag.toString()],
      ));
    }

    TrainingPackTemplateV2? replayPack;
    final mp = j['mistakePack'];
    if (mp is Map) {
      try {
        replayPack =
            TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(mp));
      } catch (_) {
        return null;
      }
    }

    return AdaptiveLearningPlan(
      recommendedTracks: tracks,
      goals: goals,
      mistakeReplayPack: replayPack,
    );
  }
}

