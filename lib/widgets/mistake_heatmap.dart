import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../helpers/poker_street_helper.dart';
import 'package:provider/provider.dart';
import '../services/saved_hand_manager_service.dart';
import 'saved_hand_list_view.dart';
import '../screens/hand_history_review_screen.dart';
import 'sync_status_widget.dart';

class MistakeHeatmap extends StatelessWidget {
  final Map<String, Map<String, int>> data;
  const MistakeHeatmap({super.key, required this.data});

  Widget _cell(
      BuildContext context, String pos, String street, int value, int max) {
    final t = max > 0 ? value / max : 0.0;
    final color = Color.lerp(Colors.transparent, Colors.redAccent, t)!;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _HeatmapMistakeHandsScreen(position: pos, street: street),
          ),
        );
      },
      child: Container(
        height: 32,
        alignment: Alignment.center,
        color: color,
        child: Text('$value', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const positions = ['BB', 'SB', 'BTN', 'CO', 'MP', 'UTG'];
    const streets = kStreetNames;
    final maxVal = positions
        .expand((p) => streets.map((s) => data[p]?[s] ?? 0))
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.white24),
        defaultColumnWidth: const FlexColumnWidth(),
        children: [
          TableRow(children: [
            const SizedBox.shrink(),
            for (final s in streets)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(s,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ]),
          for (final p in positions)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(p,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              for (final s in streets)
                _cell(context, p, s, data[p]?[s] ?? 0, maxVal),
            ]),
        ],
      ),
    );
  }
}

class _HeatmapMistakeHandsScreen extends StatelessWidget {
  final String position;
  final String street;
  const _HeatmapMistakeHandsScreen(
      {required this.position, required this.street});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final filtered = [
      for (final h in hands)
        if (h.heroPosition == position && streetName(h.boardStreet) == street) h
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$position • $street'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: SavedHandListView(
        hands: filtered,
        positions: [position],
        initialAccuracy: 'errors',
        filterKey: street,
        title: 'Ошибки: $position / $street',
        onTap: (hand) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandHistoryReviewScreen(hand: hand),
            ),
          );
        },
      ),
    );
  }
}
