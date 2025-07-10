import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/daily_ev_icm_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import '../services/png_exporter.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _boundaryKey = GlobalKey();

  Future<void> _share() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final bytes = await PngExporter.captureBoundary(boundary);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dashboard_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }


  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final target = context.watch<DailyTargetService>().target;
    final hands = stats.handsPerDay;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final days = [for (var i = 0; i < 30; i++) start.add(Duration(days: i))];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share)),
          SyncStatusIcon.of(context)
        ],
      ),
      body: RepaintBoundary(
        key: _boundaryKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final d = days[index];
              final count = hands[d] ?? 0;
              final met = count >= target;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: met ? Colors.greenAccent : Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${d.day}',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Text('$count',
                        style: const TextStyle(color: Colors.white70, fontSize: 10))
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const DailyEvIcmChart(),
        ],
        ),
      ),
    );
  }
}
