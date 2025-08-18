import 'package:flutter/material.dart';
import '../services/training_path_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_session_service.dart';
import '../widgets/unlock_gate_widget.dart';
import '../widgets/learning_path_overview_header.dart';
import '../services/learning_path_summary_cache.dart';
import '../services/streak_progress_service.dart';
import 'package:provider/provider.dart';
import 'v2/training_pack_play_screen.dart';

class LearningPathOverviewScreen extends StatefulWidget {
  const LearningPathOverviewScreen({super.key});

  @override
  State<LearningPathOverviewScreen> createState() =>
      _LearningPathOverviewScreenState();
}

class StageInfo {
  final String id;
  final List<String> packs;
  final bool unlocked;
  StageInfo({required this.id, required this.packs, required this.unlocked});
}

class _LearningPathOverviewScreenState
    extends State<LearningPathOverviewScreen> {
  late Future<List<StageInfo>> _stagesFuture;
  late Future<LearningPathSummary> _statsFuture;
  late Future<StreakData> _streakFuture;

  @override
  void initState() {
    super.initState();
    _stagesFuture = _loadStages();
    _statsFuture = _loadStats();
    _streakFuture = StreakProgressService.instance.getStreak();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _statsFuture = _loadStats();
    _streakFuture = StreakProgressService.instance.getStreak();
  }

  Future<List<StageInfo>> _loadStages() async {
    final svc = TrainingPathProgressService.instance;
    final stages = await svc.getStages();
    final ids = stages.keys.toList();
    final list = <StageInfo>[];
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      bool unlocked = true;
      if (i > 0) {
        final prev = ids[i - 1];
        final p = await svc.getProgressInStage(prev);
        unlocked = p >= 1.0;
      }
      list.add(StageInfo(id: id, packs: stages[id]!, unlocked: unlocked));
    }
    return list;
  }

  Future<LearningPathSummary> _loadStats() async {
    final cache = context.read<LearningPathSummaryCache>();
    if (cache.summary != null) return cache.summary!;
    await cache.refresh();
    return cache.summary!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StageInfo>>(
      future: _stagesFuture,
      builder: (context, snapshot) {
        final stages = snapshot.data ?? const <StageInfo>[];
        return Scaffold(
          appBar: AppBar(title: const Text('Learning Path')),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<LearningPathSummary>(
                  future: _statsFuture,
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data;
                    return ListView(
                      children: [
                        if (stats != null)
                          FutureBuilder<StreakData>(
                            future: _streakFuture,
                            builder: (context, streakSnap) {
                              final streak = streakSnap.data;
                              final msg =
                                  streak != null && streak.currentStreak > 0
                                  ? '🔥 ${streak.currentStreak}-day streak! Keep it up!'
                                  : 'Продолжай \uD83D\uDCAA';
                              return LearningPathOverviewHeader(
                                totalStages: stats.totalStages,
                                completedStages: stats.completedStages,
                                remainingPacks: stats.remainingPacks,
                                avgMastery: stats.avgMastery,
                                message: msg,
                              );
                            },
                          ),
                        for (final info in stages)
                          _StageTile(
                            stageId: info.id,
                            packIds: info.packs,
                            unlocked: info.unlocked,
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _StageTile extends StatefulWidget {
  final String stageId;
  final List<String> packIds;
  final bool unlocked;
  const _StageTile({
    required this.stageId,
    required this.packIds,
    required this.unlocked,
  });

  @override
  State<_StageTile> createState() => _StageTileState();
}

class _StageTileState extends State<_StageTile> {
  double? _progress;
  Set<String>? _completed;
  bool _loaded = false;

  Future<void> _load() async {
    final svc = TrainingPathProgressService.instance;
    final progress = await svc.getProgressInStage(widget.stageId);
    final completed = await svc.getCompletedPacksInStage(widget.stageId);
    if (mounted) {
      setState(() {
        _progress = progress;
        _completed = completed.toSet();
        _loaded = true;
      });
    }
  }

  String _title() {
    if (widget.stageId.isEmpty) return widget.stageId;
    return widget.stageId[0].toUpperCase() + widget.stageId.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress ?? 0.0;
    final tile = ExpansionTile(
      title: Row(
        children: [
          Expanded(child: Text(_title())),
          SizedBox(width: 80, child: LinearProgressIndicator(value: progress)),
        ],
      ),
      onExpansionChanged: (expanded) {
        if (expanded && !_loaded) {
          _load();
        }
      },
      children: [
        if (!_loaded)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          for (final id in widget.packIds)
            _PackTile(packId: id, completed: _completed?.contains(id) ?? false),
      ],
    );
    return UnlockGateWidget(
      unlocked: widget.unlocked,
      lockedChild: tile,
      unlockedChild: tile,
    );
  }
}

class _PackTile extends StatelessWidget {
  final String packId;
  final bool completed;
  const _PackTile({required this.packId, required this.completed});

  @override
  Widget build(BuildContext context) {
    final tpl = TrainingPackTemplateService.getById(packId, context);
    final title = tpl?.name ?? packId;
    return ListTile(
      title: Text(
        title,
        style: completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      trailing: completed ? const Text('✅') : null,
      onTap: completed
          ? null
          : () async {
              if (tpl == null) return;
              await TrainingSessionService().startFromTemplate(tpl);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingPackPlayScreen(template: tpl, original: tpl),
                  ),
                );
              }
            },
    );
  }
}
