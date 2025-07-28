import 'package:flutter/material.dart';

import '../models/booster_summary.dart';

/// Widget showing a list of [BoosterSummary] entries with EV impact info.
class BoosterFeedbackWidget extends StatelessWidget {
  final List<BoosterSummary> summaries;
  final Map<String, String>? namesById;
  final bool sortByEffectiveness;
  final bool sortByUsage;

  const BoosterFeedbackWidget({
    super.key,
    required this.summaries,
    this.namesById,
    this.sortByEffectiveness = false,
    this.sortByUsage = false,
  });

  List<BoosterSummary> _sorted() {
    final list = List<BoosterSummary>.from(summaries);
    if (sortByEffectiveness) {
      list.sort((a, b) => b.avgDeltaEV.compareTo(a.avgDeltaEV));
    } else if (sortByUsage) {
      list.sort((a, b) => b.injections.compareTo(a.injections));
    }
    return list;
  }

  String _title(String id) => namesById?[id] ?? id;

  Color _evColor(double value) {
    if (value > 0.01) return Colors.green;
    if (value < -0.01) return Colors.red;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final list = _sorted();
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stacked_line_chart, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text(
                'Booster Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < list.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(list[i].id),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  '${list[i].avgDeltaEV >= 0 ? '+' : ''}${list[i].avgDeltaEV.toStringAsFixed(3)}',
                  style: TextStyle(color: _evColor(list[i].avgDeltaEV)),
                ),
                const SizedBox(width: 8),
                Text(
                  '${list[i].injections}x',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 4),
                Icon(
                  list[i].isEffective ? Icons.star : Icons.block,
                  color: list[i].isEffective ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
            if (i != list.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
