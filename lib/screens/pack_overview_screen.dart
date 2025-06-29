import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/color_utils.dart';
import '../helpers/date_utils.dart';
import '../models/training_pack.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import 'training_pack_screen.dart';

class PackOverviewScreen extends StatefulWidget {
  const PackOverviewScreen({super.key});

  @override
  State<PackOverviewScreen> createState() => _PackOverviewScreenState();
}

class _PackOverviewScreenState extends State<PackOverviewScreen> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final storage = context.read<TrainingPackStorageService>();
    final cloud = context.read<TrainingPackCloudSyncService>();
    _sub = cloud.watch(storage);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _sharePack(TrainingPack pack) async {
    final file = await context.read<TrainingPackStorageService>().exportPackTemp(pack);
    if (!mounted || file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Check out my Poker Analyzer pack!');
    if (await file.exists()) await file.delete();
  }

  Future<void> _exportPack(TrainingPack pack) async {
    final file = await context.read<TrainingPackStorageService>().exportPack(pack);
    if (!mounted || file == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранён: ${file.path}')),
    );
  }

  Future<void> _deletePack(TrainingPack pack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить пак "${pack.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<TrainingPackStorageService>().removePack(pack);
    }
  }

  void _showMenu(TrainingPack pack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _sharePack(pack);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.white),
              title: const Text('Export', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _exportPack(pack);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _deletePack(pack);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packs = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    double avg = 0;
    int count = 0;
    for (final p in packs) {
      if (p.history.isNotEmpty) {
        final h = p.history.last;
        if (h.total > 0) {
          avg += h.correct * 100 / h.total;
          count++;
        }
      }
    }
    if (count > 0) avg /= count;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Packs'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Паков: ${packs.length}', style: const TextStyle(color: Colors.white)),
                Text('Средняя точность: ${avg.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: packs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = packs[index];
                final color = p.colorTag.isEmpty ? Colors.white24 : colorFromHex(p.colorTag);
                final progress = p.pctComplete;
                final date = p.lastAttempted > 0 ? formatDate(p.lastAttemptDate) : '-';
                return GestureDetector(
                  onLongPress: () => _showMenu(p),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: p)),
                      );
                    },
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    title: Text(p.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Последняя: $date',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
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
