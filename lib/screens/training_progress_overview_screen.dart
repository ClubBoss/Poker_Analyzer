import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../helpers/date_utils.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';

class TrainingProgressOverviewScreen extends StatelessWidget {
  static const route = '/training/progress';
  const TrainingProgressOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn)
        .toList()
      ..sort((a, b) => b.lastAttemptDate.compareTo(a.lastAttemptDate));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс по тренировкам'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ValueListenableBuilder<DateTime?>(
              valueListenable:
                  context.read<TrainingPackCloudSyncService>().lastSync,
              builder: (context, value, child) {
                final text = value == null
                    ? 'Последняя синхр.: -'
                    : 'Последняя синхр.: ${formatDateTime(value.toLocal())}';
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: packs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = packs[index];
                final progress = p.pctComplete;
                final color = progress < 0.5
                    ? Colors.redAccent
                    : progress < 0.8
                        ? AppColors.accent
                        : Colors.greenAccent;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Решено: ${p.solved}/${p.hands.length}'),
                          const Spacer(),
                          Text(
                            formatDate(p.lastAttemptDate),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
