import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import '../models/learning_track_progress_model.dart';
import '../services/learning_path_gatekeeper_service.dart';
import '../services/learning_track_progress_service.dart';
import '../services/training_path_progress_service_v2.dart';
import '../services/tag_mastery_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/training_progress_service.dart';
import '../services/skill_gap_booster_service.dart';
import '../services/mistake_tag_history_service.dart';
import '../models/mistake_tag_cluster.dart';
import '../models/sub_stage_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../widgets/skill_card.dart';

class LearningPathStageDetailedScreen extends StatefulWidget {
  final LearningPathTemplateV2 path;
  final LearningPathStageModel stage;
  const LearningPathStageDetailedScreen({
    super.key,
    required this.path,
    required this.stage,
  });

  @override
  State<LearningPathStageDetailedScreen> createState() =>
      _LearningPathStageDetailedScreenState();
}

class _LearningPathStageDetailedScreenState
    extends State<LearningPathStageDetailedScreen> {
  late SessionLogService _logs;
  late TrainingPathProgressServiceV2 _progress;
  late LearningPathGatekeeperService _gatekeeper;
  late LearningTrackProgressService _service;
  bool _initialized = false;

  bool _loading = true;
  Map<String, double> _mastery = {};
  Map<String, int> _xpMap = {};
  List<TrainingPackTemplateV2> _boosters = [];
  StageStatus _status = StageStatus.locked;
  final Map<String, double> _subProgress = {};
  final Map<String, double> _subAccuracy = {};
  final Map<String, TrainingPackTemplateV2> _subBoosters = {};
  List<String> _reasons = [];
  bool _stageDone = false;
  int _stageHands = 0;
  double _stageAccuracy = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _logs = context.read<SessionLogService>();
      _progress = TrainingPathProgressServiceV2(logs: _logs);
      _gatekeeper = LearningPathGatekeeperService(
        progress: _progress,
        mastery: context.read<TagMasteryService>(),
      );
      _service = LearningTrackProgressService(
        progress: _progress,
        gatekeeper: _gatekeeper,
      );
      _load();
      _initialized = true;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _logs.load();
    final masteryService = context.read<TagMasteryService>();
    final xpService = context.read<XPTrackerService>();
    final masteryMap = await masteryService.computeMastery();
    final xpMap = await xpService.getTotalXpPerTag();
    final progSvc = TrainingProgressService.instance;
    final subProg = <String, double>{};
    final subAcc = <String, double>{};
    final subBoosters = <String, TrainingPackTemplateV2>{};
    final boosterService = const SkillGapBoosterService();
    final tracker = const LearningPathProgressTrackerService();
    final aggregated = tracker.aggregateLogsByPack(_logs.logs);
    var stageHands = 0;
    var stageCorrect = 0;
    var stageDone = widget.stage.subStages.isNotEmpty;
    for (final s in widget.stage.subStages) {
      final p = await progSvc.getSubStageProgress(widget.stage.id, s.packId);
      subProg[s.packId] = p;
      final log = aggregated[s.packId];
      final hands = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
      final acc = hands == 0 ? 0.0 : log!.correctCount / hands * 100;
      stageHands += hands;
      stageCorrect += log?.correctCount ?? 0;
      subAcc[s.packId] = acc;
      if (acc < s.requiredAccuracy && s.requiredAccuracy > 0) {
        final tags = s.objectives.isNotEmpty ? s.objectives : widget.stage.tags;
        if (tags.isNotEmpty) {
          final packs = await boosterService.suggestBoosters(
            requiredTags: tags,
            masteryMap: masteryMap,
            count: 1,
          );
          if (packs.isNotEmpty) subBoosters[s.packId] = packs.first;
        }
      }
      if (p < 1.0) stageDone = false;
    }
    final stageAcc = stageHands == 0 ? 0.0 : stageCorrect * 100 / stageHands;
    final boosters = await boosterService.suggestBoosters(
      requiredTags: widget.stage.tags,
      masteryMap: masteryMap,
      count: 3,
    );
    final model = await _service.build(widget.path.id);
    final status =
        model.statusFor(widget.stage.id)?.status ?? StageStatus.locked;
    final reasons = <String>[];
    if (status == StageStatus.locked) {
      final threshold = _gatekeeper.masteryThreshold;
      for (final t in widget.stage.tags) {
        final m = masteryMap[t.toLowerCase()] ?? 1.0;
        if (m < threshold) {
          reasons.add('Низкий навык: $t');
        }
      }
      final freq = await MistakeTagHistoryService.getTagsByFrequency();
      final blocked = <MistakeTagCluster>{};
      for (final e in freq.entries) {
        if (e.value >= _gatekeeper.mistakeThreshold) {
          blocked.add(_gatekeeper.clusterService.getClusterForTag(e.key));
        }
      }
      for (final c in blocked) {
        if (widget.stage.tags
            .any((t) => t.toLowerCase() == c.label.toLowerCase())) {
          reasons.add('Частые ошибки: ${c.label}');
        }
      }
      if (_gatekeeper.minSessions > 0 &&
          _logs.logs.length < _gatekeeper.minSessions) {
        reasons.add('Требуется сессий: ${_gatekeeper.minSessions}');
      }
    }
    if (!mounted) return;
    setState(() {
      _mastery = masteryMap;
      _xpMap = xpMap;
      _subProgress
        ..clear()
        ..addAll(subProg);
      _subAccuracy
        ..clear()
        ..addAll(subAcc);
      _subBoosters
        ..clear()
        ..addAll(subBoosters);
      _boosters = boosters;
      _status = status;
      _reasons = reasons;
      _stageDone = stageDone;
      _stageHands = stageHands;
      _stageAccuracy = stageAcc;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final template =
        await PackLibraryService.instance.getById(widget.stage.packId);
    if (template == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training pack not found')),
      );
      return;
    }
    await const TrainingSessionLauncher().launch(template);
    if (mounted) _load();
  }

  Future<void> _startSub(SubStageModel sub) async {
    final template = await PackLibraryService.instance.getById(sub.packId);
    if (template == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training pack not found')),
      );
      return;
    }
    final copy = TrainingPackTemplateV2.fromJson(template.toJson())
      ..name = sub.title
      ..description =
          sub.description.isNotEmpty ? sub.description : template.description;
    await const TrainingSessionLauncher().launch(copy);
    if (mounted) _load();
  }

  Widget _buildBoosterCard(TrainingPackTemplateV2 pack) {
    final accent = Theme.of(context).colorScheme.secondary;
    final desc = pack.goal.isNotEmpty ? pack.goal : pack.description;
    return GestureDetector(
      onTap: () => const TrainingSessionLauncher().launch(pack),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pack.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            const Spacer(),
            Text(
              '${pack.spotCount} spots',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStageRow(SubStageModel sub) {
    final prog = _subProgress[sub.packId] ?? 0.0;
    final done = prog >= 1.0;
    final acc = _subAccuracy[sub.packId] ?? 0.0;
    final booster = _subBoosters[sub.packId];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (sub.description.isNotEmpty)
                      Text(
                        sub.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: prog),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sub.minHands} рук · ${sub.requiredAccuracy.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  done
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => _startSub(sub),
                          child: const Text('Начать'),
                        ),
                  if (booster != null && acc < sub.requiredAccuracy)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ElevatedButton(
                        onPressed: () =>
                            const TrainingSessionLauncher().launch(booster),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: const Text('Усилить 🔥'),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (booster != null && acc < sub.requiredAccuracy)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Text(
                booster.name,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stage Complete',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Hands: \$_stageHands'),
          Text('Accuracy: \${_stageAccuracy.toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _start,
                child: const Text('Review Stage'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  await _service.advanceToNextStage(widget.stage.id);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stage.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.stage.description.isNotEmpty)
                  Text(
                    widget.stage.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (widget.stage.subStages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Подэтапы',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final sub in widget.stage.subStages)
                    _buildSubStageRow(sub),
                ],
                if (widget.stage.objectives.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Навыки',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: -4,
                    children: [
                      for (final o in widget.stage.objectives)
                        Chip(label: Text(o)),
                    ],
                  ),
                ],
                if (widget.stage.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Теги',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in widget.stage.tags)
                        SizedBox(
                          width: 160,
                          child: SkillCard(
                            tag: t,
                            mastery: _mastery[t.toLowerCase()] ?? 0,
                            totalXp: _xpMap[t.toLowerCase()] ?? 0,
                          ),
                        ),
                    ],
                  ),
                ],
                if (_status == StageStatus.locked && _reasons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Причины блокировки',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final r in _reasons)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('- $r',
                          style: const TextStyle(color: Colors.white70)),
                    ),
                ],
                if (_boosters.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '🩹 Booster Packs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, i) =>
                          _buildBoosterCard(_boosters[i]),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: _boosters.length,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _stageDone
                    ? _buildStageSummary()
                    : Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed:
                              _status == StageStatus.unlocked ? _start : null,
                          child: const Text('Начать тренировку'),
                        ),
                      ),
              ],
            ),
    );
  }
}
