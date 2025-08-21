import 'package:collection/collection.dart';

import '../models/leak_insight.dart';
import '../models/session_log.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_template_v2.dart';

class WeaknessInsightService {
  const WeaknessInsightService();

  List<LeakInsight> analyze({
    required List<SessionLog> logs,
    required List<TrainingPackTemplateV2> packs,
  }) {
    final byId = {for (final p in packs) p.id: p};
    final stats = <_Key, _Mutable>{};

    for (final log in logs) {
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final hands = log.correctCount + log.mistakeCount;
      if (hands <= 0) continue;
      final tags = <String>{
        ...tpl.tags.map((e) => e.toLowerCase()),
        if (tpl.category != null) tpl.category!.toLowerCase(),
      }..removeWhere((e) => e.isEmpty);
      final positions = tpl.positions.isNotEmpty
          ? tpl.positions.map(parseHeroPosition).toList()
          : [HeroPosition.unknown];
      final stack = tpl.bb;
      for (final tag in tags) {
        for (final pos in positions) {
          final key = _Key(tag, pos, stack);
          final s = stats.putIfAbsent(key, () => _Mutable());
          s.hands += hands;
          s.mistakes += log.mistakeCount;
        }
      }
    }

    final insights = <LeakInsight>[];
    for (final entry in stats.entries) {
      final h = entry.value.hands;
      if (h < 10) continue;
      final acc = h > 0 ? (h - entry.value.mistakes) / h : 1.0;
      if (acc >= 0.8) continue;
      final score = (1 - acc) * (1 + 10 / h);
      final suggestion = packs.firstWhereOrNull((p) {
        final tagMatch = p.tags
            .map((e) => e.toLowerCase())
            .contains(entry.key.tag);
        final posMatch = p.positions
            .map(parseHeroPosition)
            .contains(entry.key.pos);
        return tagMatch && posMatch && p.bb == entry.key.stack;
      });
      insights.add(
        LeakInsight(
          tag: entry.key.tag,
          position: entry.key.pos.label,
          stack: entry.key.stack,
          suggestedPackId: suggestion?.id ?? '',
          leakScore: double.parse(score.toStringAsFixed(2)),
        ),
      );
    }

    insights.sort((a, b) => b.leakScore.compareTo(a.leakScore));
    return insights;
  }
}

class _Mutable {
  int hands = 0;
  int mistakes = 0;
}

class _Key {
  final String tag;
  final HeroPosition pos;
  final int stack;
  const _Key(this.tag, this.pos, this.stack);

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.tag == tag &&
      other.pos == pos &&
      other.stack == stack;

  @override
  int get hashCode => Object.hash(tag, pos, stack);
}
