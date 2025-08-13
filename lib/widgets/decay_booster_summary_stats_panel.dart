import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/decay_tag_reinforcement_event.dart';
import '../services/tag_retention_tracker.dart';

/// Compact panel summarizing how many decayed skills were reinforced in a booster session.
class DecayBoosterSummaryStatsPanel extends StatefulWidget {
  final List<DecayTagReinforcementEvent> events;
  final bool initiallyExpanded;
  const DecayBoosterSummaryStatsPanel({
    super.key,
    required this.events,
    this.initiallyExpanded = false,
  });

  @override
  State<DecayBoosterSummaryStatsPanel> createState() =>
      _DecayBoosterSummaryStatsPanelState();
}

class _DecayBoosterSummaryStatsPanelState
    extends State<DecayBoosterSummaryStatsPanel> {
  late Future<_SummaryData> _future;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _future = _load();
  }

  Future<_SummaryData> _load() async {
    final decayed = await context.read<TagRetentionTracker>().getDecayedTags();
    final decayedSet = decayed.map((e) => e.toLowerCase()).toSet();
    final filtered = widget.events
        .where((e) => decayedSet.contains(e.tag.toLowerCase()))
        .toList();
    if (filtered.isEmpty) return const _SummaryData.empty();
    final tags = filtered.map((e) => e.tag.toLowerCase()).toSet().length;
    final delta = filtered.fold<double>(0.0, (s, e) => s + e.delta);
    return _SummaryData(tags: tags, delta: delta, events: filtered);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SummaryData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        if (data.isEmpty) return const SizedBox.shrink();
        final deltaStr = data.delta >= 0
            ? '+${data.delta.toStringAsFixed(2)}'
            : data.delta.toStringAsFixed(2);
        final summary =
            '🎯 ${data.tags} забытых навыков восстановлены · $deltaStr мастерства';
        final accent = Theme.of(context).colorScheme.secondary;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (v) => setState(() => _expanded = v),
            title: Text(summary, style: const TextStyle(color: Colors.white70)),
            collapsedIconColor: Colors.white,
            iconColor: Colors.white,
            textColor: Colors.white,
            childrenPadding: const EdgeInsets.all(12),
            children: [
              for (final e in data.events)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.tag,
                          style: const TextStyle(color: Colors.white70)),
                      Text(
                        e.delta >= 0
                            ? '+${e.delta.toStringAsFixed(2)}'
                            : e.delta.toStringAsFixed(2),
                        style: TextStyle(
                          color: e.delta >= 0 ? accent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryData {
  final int tags;
  final double delta;
  final List<DecayTagReinforcementEvent> events;
  const _SummaryData(
      {required this.tags, required this.delta, required this.events});
  const _SummaryData.empty()
      : tags = 0,
        delta = 0,
        events = const [];
  bool get isEmpty => tags == 0;
}
