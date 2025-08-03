import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../services/training_pack_stats_service.dart';
import '../../services/pinned_learning_service.dart';

enum PlayOrder { sequential, random, mistakes }

class SpotFeedback {
  final String action;
  final double? heroEv;
  final double? evDiff;
  final double? icmDiff;
  final bool correct;
  final bool repeated;
  final String? advice;
  const SpotFeedback(this.action, this.heroEv, this.evDiff, this.icmDiff,
      this.correct, this.repeated, this.advice);
}

mixin TrainingPackPlayCore<T extends StatefulWidget> on State<T> {
  // Shared state
  List<TrainingPackSpot> get spots;
  set spots(List<TrainingPackSpot> value);

  Map<String, String> get results;
  set results(Map<String, String> value);

  int get index;
  set index(int value);

  bool get loading;
  set loading(bool value);

  PlayOrder get order;
  set order(PlayOrder value);

  int get streetCount;
  set streetCount(int value);

  Map<String, int> get handCounts;
  Map<String, int> get handTotals;

  bool get summaryShown;
  set summaryShown(bool value);

  bool get autoAdvance;
  set autoAdvance(bool value);

  SpotFeedback? get feedback;
  set feedback(SpotFeedback? value);

  Timer? get feedbackTimer;
  set feedbackTimer(Timer? value);

  TrainingPackTemplate get template;

  Future<void> save({bool ts = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tpl_seq_${template.id}',
        [for (final s in spots) s.id]);
    await prefs.setInt('tpl_prog_${template.id}', index);
    await prefs.setString('tpl_res_${template.id}', jsonEncode(results));
    if (template.targetStreet != null) {
      await prefs.setInt('tpl_street_${template.id}', streetCount);
    }
    if (template.focusHandTypes.isNotEmpty) {
      await prefs.setString('tpl_hand_${template.id}', jsonEncode(handCounts));
    }
    if (ts) {
      await prefs.setInt('tpl_ts_${template.id}',
          DateTime.now().millisecondsSinceEpoch);
    }
    unawaited(
        TrainingPackStatsService.setLastIndex(template.id, index));
    await PinnedLearningService.instance
        .setLastPosition('pack', template.id, index);
  }

  bool matchStreet(TrainingPackSpot spot) {
    final len = spot.hand.board.length;
    switch (template.targetStreet) {
      case 'flop':
        return len == 3;
      case 'turn':
        return len == 4;
      case 'river':
        return len == 5;
      default:
        return false;
    }
  }
}

