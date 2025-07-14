import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/progress_export_service.dart';
import '../services/training_stats_service.dart';
import '../theme/app_colors.dart';

class TrainingSummaryScreen extends StatelessWidget {
  final int correct;
  final int total;
  final Duration elapsed;
  final VoidCallback onRepeat;
  final VoidCallback onBack;
  const TrainingSummaryScreen({
    super.key,
    required this.correct,
    required this.total,
    required this.elapsed,
    required this.onRepeat,
    required this.onBack,
  });

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _share(BuildContext context) async {
    final stats = context.read<TrainingStatsService>();
    final service = ProgressExportService(stats: stats);
    final file = await service.exportPdf();
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : correct * 100 / total;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$correct/$total',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Accuracy: ${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Time: ${_format(elapsed)}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRepeat, child: const Text('Repeat')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () => _share(context),
                  child: const Text('Share')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
            ],
          ),
        ),
      ),
    );
  }
}
