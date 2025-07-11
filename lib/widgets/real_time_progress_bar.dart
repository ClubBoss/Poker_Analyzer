import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/real_time_progress_service.dart';

class RealTimeProgressBar extends StatelessWidget {
  const RealTimeProgressBar({super.key});

  Widget _item(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<RealTimeProgressService>().progress;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('Acc', '${(progress.accuracy * 100).toStringAsFixed(1)}%'),
          _item('EV', progress.ev.toStringAsFixed(2)),
          _item('ICM', progress.icm.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
