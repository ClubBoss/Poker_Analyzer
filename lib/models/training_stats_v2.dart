import 'package:flutter/material.dart';

import 'session_log.dart';
import 'v2/training_pack_template_v2.dart';
import 'v2/hero_position.dart';

class TrainingStatsV2Model {
  final int totalHands;
  final double accuracy;
  final Map<HeroPosition, int> handsByPosition;
  final Map<HeroPosition, double> accuracyByPosition;
  final Map<int, int> handsByStack;
  final Map<int, double> accuracyByStack;
  final Map<String, double> accuracyByTag;

  TrainingStatsV2Model({
    required this.totalHands,
    required this.accuracy,
    required this.handsByPosition,
    required this.accuracyByPosition,
    required this.handsByStack,
    required this.accuracyByStack,
    required this.accuracyByTag,
  });

  static TrainingStatsV2Model compute({
    required List<SessionLog> logs,
    required List<TrainingPackTemplateV2> library,
    DateTimeRange? range,
    HeroPosition? position,
    int? stack,
    String? tag,
  }) {
    final byId = {for (final t in library) t.id: t};
    int totalHands = 0;
    int totalCorrect = 0;
    final posHands = <HeroPosition, int>{};
    final posCorrect = <HeroPosition, int>{};
    final stackHands = <int, int>{};
    final stackCorrect = <int, int>{};
    final tagHands = <String, int>{};
    final tagCorrect = <String, int>{};
    for (final log in logs) {
      if (range != null) {
        if (log.completedAt.isBefore(range.start) ||
            log.completedAt.isAfter(range.end)) {
          continue;
        }
      }
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final positions = tpl.positions.isNotEmpty
          ? tpl.positions.map(parseHeroPosition).toList()
          : [HeroPosition.unknown];
      final bb = tpl.bb;
      final tags = [for (final t in tpl.tags) t.toLowerCase()];
      if (position != null && !positions.contains(position)) continue;
      if (stack != null && bb != stack) continue;
      if (tag != null && !tags.contains(tag.toLowerCase())) continue;
      final hands = log.correctCount + log.mistakeCount;
      final correct = log.correctCount;
      totalHands += hands;
      totalCorrect += correct;
      for (final p in positions) {
        posHands[p] = (posHands[p] ?? 0) + hands;
        posCorrect[p] = (posCorrect[p] ?? 0) + correct;
      }
      stackHands[bb] = (stackHands[bb] ?? 0) + hands;
      stackCorrect[bb] = (stackCorrect[bb] ?? 0) + correct;
      for (final tg in tags) {
        tagHands[tg] = (tagHands[tg] ?? 0) + hands;
        tagCorrect[tg] = (tagCorrect[tg] ?? 0) + correct;
      }
    }
    double calc(int c, int h) => h > 0 ? c / h : 0.0;
    final accByPos = {
      for (final p in posHands.keys) p: calc(posCorrect[p] ?? 0, posHands[p]!),
    };
    final accByStack = {
      for (final s in stackHands.keys)
        s: calc(stackCorrect[s] ?? 0, stackHands[s]!),
    };
    final accByTag = {
      for (final t in tagHands.keys) t: calc(tagCorrect[t] ?? 0, tagHands[t]!),
    };
    final overall = calc(totalCorrect, totalHands);
    return TrainingStatsV2Model(
      totalHands: totalHands,
      accuracy: overall,
      handsByPosition: posHands,
      accuracyByPosition: accByPos,
      handsByStack: stackHands,
      accuracyByStack: accByStack,
      accuracyByTag: accByTag,
    );
  }
}
