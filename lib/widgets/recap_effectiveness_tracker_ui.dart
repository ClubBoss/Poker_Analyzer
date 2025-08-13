import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/recap_effectiveness_analyzer.dart';
import '../services/recap_tag_analytics_service.dart';
import '../services/session_log_service.dart';

class RecapEffectivenessTrackerUI extends StatefulWidget {
  final List<String> tags;
  const RecapEffectivenessTrackerUI({super.key, required this.tags});

  @override
  State<RecapEffectivenessTrackerUI> createState() =>
      _RecapEffectivenessTrackerUIState();
}

class _TagInfo {
  final String tag;
  final double? mistakeRate;
  final double repeatRate;
  final double improvement;
  const _TagInfo({
    required this.tag,
    this.mistakeRate,
    required this.repeatRate,
    required this.improvement,
  });
}

class _RecapEffectivenessTrackerUIState
    extends State<RecapEffectivenessTrackerUI> {
  late Future<List<_TagInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_TagInfo>> _load() async {
    final logs = context.read<SessionLogService>();
    await logs.load();
    await RecapEffectivenessAnalyzer.instance.refresh();
    final improvements = await context
        .read<RecapTagAnalyticsService>()
        .computeRecapTagImprovements();
    final list = <_TagInfo>[];
    for (final raw in widget.tags) {
      final tag = raw.trim().toLowerCase();
      if (tag.isEmpty) continue;
      final effect = RecapEffectivenessAnalyzer.instance.stats[tag];
      double? mistakeRate;
      int total = 0;
      int mistakes = 0;
      for (final log in logs.logs) {
        final tags = {for (final t in log.tags) t.trim().toLowerCase()};
        if (!tags.contains(tag)) continue;
        if (tags.contains('recap') || tags.contains('reinforcement')) continue;
        total += log.correctCount + log.mistakeCount;
        mistakes += log.mistakeCount;
      }
      if (total > 0) mistakeRate = mistakes / total;
      list.add(_TagInfo(
        tag: tag,
        mistakeRate: mistakeRate,
        repeatRate: effect?.repeatRate ?? 0,
        improvement: improvements[tag]?.improvement ?? 0,
      ));
    }
    return list;
  }

  Color _trendColor(double v) {
    if (v > 0) return Colors.green;
    if (v < 0) return Colors.red;
    return Colors.grey;
  }

  IconData _trendIcon(double v) {
    if (v > 0) return Icons.trending_up;
    if (v < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_TagInfo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final info in items) _buildRow(info),
          ],
        );
      },
    );
  }

  Widget _buildRow(_TagInfo info) {
    final trendColor = _trendColor(info.improvement);
    final trendIcon = _trendIcon(info.improvement);
    final mistakes = info.mistakeRate != null
        ? '${(info.mistakeRate! * 100).toStringAsFixed(1)}%'
        : '--';
    final repeat = '${(info.repeatRate * 100).toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info.tag,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            'Mistakes: $mistakes',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            'Repeat: $repeat',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
