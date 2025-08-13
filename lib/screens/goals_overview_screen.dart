import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/goals_service.dart';
import '../widgets/sync_status_widget.dart';

class GoalsOverviewScreen extends StatelessWidget {
  const GoalsOverviewScreen({super.key});

  Future<void> _editHands(BuildContext context) async {
    final service = context.read<GoalsService>();
    final ctrl =
        TextEditingController(text: service.weeklyHandsTarget.toString());
    final val = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Цель раздач за неделю'),
        content:
            TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: const Text('OK')),
        ],
      ),
    );
    if (val != null) await service.setWeeklyHandsTarget(val);
  }

  Future<void> _editAccuracy(BuildContext context) async {
    final service = context.read<GoalsService>();
    final ctrl = TextEditingController(
        text: service.weeklyAccuracyTarget.toStringAsFixed(1));
    final val = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Цель точности %'),
        content:
            TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
              child: const Text('OK')),
        ],
      ),
    );
    if (val != null) await service.setWeeklyAccuracyTarget(val);
  }

  Widget _tile(BuildContext context,
      {required String title,
      required double progress,
      required double target,
      required double prev,
      required VoidCallback onEdit,
      bool percent = false}) {
    final accent = Theme.of(context).colorScheme.secondary;
    final completed = progress >= target;
    final bar = target == 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
    final pText = percent
        ? '${progress.toStringAsFixed(1)}%'
        : progress.round().toString();
    final tText =
        percent ? '${target.toStringAsFixed(1)}%' : target.round().toString();
    final prevText =
        percent ? '${prev.toStringAsFixed(1)}%' : prev.round().toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (completed)
                const Icon(Icons.emoji_events, color: Colors.amber),
              IconButton(
                  icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: bar,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('$pText / $tText'),
          Text('Прошлая неделя: $prevText',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoalsService>();
    final hands = service.weeklyHandsProgress().toDouble();
    final handsPrev = service.weeklyHandsPrevious().toDouble();
    final accuracy = service.weeklyAccuracyProgress();
    final accuracyPrev = service.weeklyAccuracyPrevious();
    return Scaffold(
      appBar: AppBar(title: const Text('Цели'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        actions: [SyncStatusIcon.of(context)],
        children: [
          _tile(context,
              title: 'Раздач за неделю',
              progress: hands,
              target: service.weeklyHandsTarget.toDouble(),
              prev: handsPrev,
              onEdit: () => _editHands(context)),
          _tile(context,
              title: 'Средняя точность',
              progress: accuracy,
              target: service.weeklyAccuracyTarget,
              prev: accuracyPrev,
              onEdit: () => _editAccuracy(context),
              percent: true),
        ],
      ),
    );
  }
}
