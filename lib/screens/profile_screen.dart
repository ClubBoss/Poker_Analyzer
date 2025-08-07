import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fl_chart/fl_chart.dart';
import '../services/streak_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/template_storage_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';
import '../widgets/training_progress_chart_widget.dart';
import 'basic_achievements_screen.dart';
import 'booster_library_screen.dart';
import 'booster_archive_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _evaluated;
  late int _correct;
  final List<MapEntry<TrainingPackStat, String>> _stats = [];
  int? _progressRange = 7;

  void _load() {
    final service = EvaluationExecutorService();
    _evaluated = service.totalEvaluated;
    _correct = service.totalCorrect;
  }

  Future<void> _loadStats() async {
    final templates = context.read<TemplateStorageService>().templates;
    final recent = await TrainingPackStatsService.recentlyPractisedTemplates(
      templates,
      days: 30,
    );
    final list = <MapEntry<TrainingPackStat, String>>[];
    for (final t in recent) {
      final stat = await TrainingPackStatsService.getStats(t.id);
      if (stat != null) list.add(MapEntry(stat, t.name));
    }
    list.sort((a, b) => b.key.last.compareTo(a.key.last));
    if (list.length > 5) list.removeRange(5, list.length);
    if (!mounted) return;
    setState(() {
      _stats
        ..clear()
        ..addAll(list);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _reset() async {
    await EvaluationExecutorService().resetAccuracy();
    setState(_load);
  }

  Widget _legendItem(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      );

  Widget _buildChart() {
    if (_stats.isEmpty) {
      return Container(
        height: responsiveSize(context, 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Недостаточно данных',
            style: TextStyle(color: Colors.white70)),
      );
    }
    final preEv = <FlSpot>[];
    final postEv = <FlSpot>[];
    final preIcm = <FlSpot>[];
    final postIcm = <FlSpot>[];
    for (var i = 0; i < _stats.length; i++) {
      final s = _stats[i].key;
      preEv.add(FlSpot(i.toDouble(), s.preEvPct));
      postEv.add(FlSpot(i.toDouble(), s.postEvPct));
      preIcm.add(FlSpot(i.toDouble(), s.preIcmPct));
      postIcm.add(FlSpot(i.toDouble(), s.postIcmPct));
    }
    final step = (_stats.length / 5).ceil();
    final lines = [
      LineChartBarData(
        spots: preEv,
        color: AppColors.evPre,
        barWidth: 2,
        isCurved: false,
        dotData: const FlDotData(show: true),
      ),
      LineChartBarData(
        spots: postEv,
        color: AppColors.evPost,
        barWidth: 2,
        isCurved: false,
        dotData: const FlDotData(show: true),
      ),
      LineChartBarData(
        spots: preIcm,
        color: AppColors.icmPre,
        barWidth: 2,
        isCurved: false,
        dotData: const FlDotData(show: true),
      ),
      LineChartBarData(
        spots: postIcm,
        color: AppColors.icmPost,
        barWidth: 2,
        isCurved: false,
        dotData: const FlDotData(show: true),
      ),
    ];
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItems: (spots) {
                        final idx = spots.first.spotIndex;
                        final e = _stats[idx];
                        return [
                          LineTooltipItem(
                            '${e.value}\nEV ${e.key.preEvPct.toStringAsFixed(1)} → ${e.key.postEvPct.toStringAsFixed(1)}\nICM ${e.key.preIcmPct.toStringAsFixed(1)} → ${e.key.postIcmPct.toStringAsFixed(1)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          )
                        ];
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) =>
                        const FlLine(color: Colors.white24, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _stats.length) {
                            return const SizedBox.shrink();
                          }
                          if (index % step != 0 && index != _stats.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final d = _stats[index].key.last;
                          final label =
                              '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                          return Text(label,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.white24),
                      bottom: BorderSide(color: Colors.white24),
                    ),
                  ),
                  lineBarsData: lines,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              _legendItem(AppColors.evPre, 'Pre EV'),
              _legendItem(AppColors.evPost, 'Post EV'),
              _legendItem(AppColors.icmPre, 'Pre ICM'),
              _legendItem(AppColors.icmPost, 'Post ICM'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>().count;
    final acc = _evaluated == 0 ? 0 : _correct / _evaluated;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Streak: $streak',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Accuracy: ${(acc * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Your Progress',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [
                _progressRange == 7,
                _progressRange == 30,
                _progressRange == null,
              ],
              onPressed: (index) {
                setState(() {
                  _progressRange = const [7, 30, null][index];
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('7 days'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('30 days'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('All time'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TrainingProgressChartWidget(dayRange: _progressRange),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reset,
              child: const Text('Reset Accuracy'),
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                );
              },
              child: const Text('Достижения'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BoosterLibraryScreen(),
                  ),
                );
              },
              child: const Text('Booster Library'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BoosterArchiveScreen(),
                  ),
                );
              },
              child: const Text('Booster Archive'),
            ),
            const SizedBox(height: 16),
            Consumer<AuthService>(
              builder: (context, auth, child) {
                if (auth.isSignedIn) {
                  final email = auth.email;
                  return ElevatedButton(
                    onPressed: auth.signOut,
                    child: Text('Sign Out ($email)'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                      final ok = await auth.signInWithGoogle();
                      if (ok) {
                        final cloud = context.read<CloudSyncService>();
                        await cloud.syncDown();
                        await context
                            .read<TrainingPackCloudSyncService>()
                            .syncDownStats();
                      }
                    },
                    child: const Text('Sign In with Google'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await auth.signInWithApple();
                      if (ok) {
                        final cloud = context.read<CloudSyncService>();
                        await cloud.syncDown();
                        await context
                            .read<TrainingPackCloudSyncService>()
                            .syncDownStats();
                      }
                    },
                    child: const Text('Sign In with Apple'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
}
