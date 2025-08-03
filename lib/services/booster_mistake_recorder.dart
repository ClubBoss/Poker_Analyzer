import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math';


import '../models/training_spot_attempt.dart';
import '../models/v2/training_action.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'auto_mistake_tagger_engine.dart';
import 'mistake_tag_history_service.dart';

class BoosterMistakeRecorder {
  BoosterMistakeRecorder._();
  static final BoosterMistakeRecorder instance = BoosterMistakeRecorder._();

  static const _enabledKey = 'booster_mistake_recorder_enabled';
  bool _enabled = true;
  final Set<String> _recorded = <String>{};

  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> recordSession({
    required TrainingPackTemplateV2 booster,
    required List<TrainingAction> actions,
    required List<TrainingPackSpot> spots,
  }) async {
    if (!_enabled) return;
    final map = {for (final s in spots) s.id: s};
    for (final a in actions) {
      if (a.isCorrect) continue;
      if (!_recorded.add(a.spotId)) continue;
      final spot = map[a.spotId];
      if (spot == null) continue;
      final correct = spot.correctAction ?? '';
      final heroEv = _actionEv(spot, a.chosenAction);
      final bestEv = _bestEv(spot);
      final diff = _calcEvDiff(heroEv, bestEv, a.chosenAction, correct) ?? 0;
      final attempt = TrainingSpotAttempt(
        spot: spot,
        userAction: a.chosenAction,
        correctAction: correct,
        evDiff: diff,
      );
      final tags = const AutoMistakeTaggerEngine().tag(attempt);
      await MistakeTagHistoryService.logTags(booster.id, attempt, tags);
    }
    _recorded.clear();
  }

  double? _actionEv(TrainingPackSpot spot, String action) {
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot spot) {
    double? best;
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : max(best, a.ev!);
      }
    }
    return best;
  }

  double? _calcEvDiff(
    double? heroEv,
    double? bestEv,
    String user,
    String correct,
  ) {
    if (heroEv == null || bestEv == null) return null;
    final c = correct.toLowerCase();
    if (c == 'push' || c == 'call' || c == 'raise') {
      return bestEv - heroEv;
    }
    return heroEv - bestEv;
  }
}
