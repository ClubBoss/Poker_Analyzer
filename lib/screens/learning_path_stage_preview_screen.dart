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
import '../services/skill_gap_booster_service.dart';
import '../services/mistake_tag_history_service.dart';
import '../models/mistake_tag_cluster.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../widgets/skill_card.dart';

class LearningPathStagePreviewScreen extends StatefulWidget {
  final LearningPathTemplateV2 path;
  final LearningPathStageModel stage;
  const LearningPathStagePreviewScreen({
    super.key,
    required this.path,
    required this.stage,
  });

  @override
  State<LearningPathStagePreviewScreen> createState() =>
      _LearningPathStagePreviewScreenState();
}

class _LearningPathStagePreviewScreenState
    extends State<LearningPathStagePreviewScreen> {
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
  List<String> _reasons = [];

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
    final boosterService = const SkillGapBoosterService();
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
      _boosters = boosters;
      _status = status;
      _reasons = reasons;
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.title,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (sub.description.isNotEmpty)
                                  Text(
                                    sub.description,
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${sub.minHands} рук · ${sub.requiredAccuracy.toStringAsFixed(0)}%',
                            style:
                                const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _status == StageStatus.unlocked ? _start : null,
                    child: const Text('Начать тренировку'),
                  ),
                ),
              ],
            ),
    );
  }
}
