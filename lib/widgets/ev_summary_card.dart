import 'dart:math';
import 'package:flutter/material.dart';

List<int> bucketize(List<double> values, int count) {
  final result = List<int>.filled(count, 0);
  if (values.isEmpty) return result;
  final minV = values.reduce(min);
  final maxV = values.reduce(max);
  if (minV == maxV) {
    result[count ~/ 2] = values.length;
    return result;
  }
  final step = (maxV - minV) / count;
  for (final v in values) {
    var idx = ((v - minV) / step).floor();
    if (idx < 0) idx = 0;
    if (idx >= count) idx = count - 1;
    result[idx]++;
  }
  return result;
}

class EvSummaryCard extends StatelessWidget {
  final List<double> values;
  final bool isIcm;
  final VoidCallback onToggle;
  const EvSummaryCard(
      {super.key,
      required this.values,
      required this.isIcm,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        height: 80,
        alignment: Alignment.center,
        child: const Text('No EV data'),
      );
    }
    final avg = values.reduce((a, b) => a + b) / values.length;
    final pos = values.where((v) => v > 0).length;
    final neg = values.where((v) => v < 0).length;
    final bins = bucketize(values, 10);
    final maxCount = bins.reduce(max);
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final step = (maxV - minV) / 10;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(isIcm ? 'ICM mode' : 'EV mode')),
              IconButton(
                  icon: const Icon(Icons.swap_horiz), onPressed: onToggle),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Avg: ${avg >= 0 ? '+' : ''}${isIcm ? avg.toStringAsFixed(3) : avg.toStringAsFixed(2)} ${isIcm ? 'prize' : 'BB'}',
                ),
              ),
              Text(
                  '+EV: ${(pos / values.length * 100).round()} %   -EV: ${(neg / values.length * 100).round()} %'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 10; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: maxCount == 0 ? 0 : bins[i] / maxCount * 40,
                      color: () {
                        final mid = minV + step * (i + 0.5);
                        if (mid > 0) return Colors.green;
                        if (mid < 0) return Colors.red;
                        return Colors.grey;
                      }(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
