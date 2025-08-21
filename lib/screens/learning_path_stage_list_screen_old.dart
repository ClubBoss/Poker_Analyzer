import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/learning_track_progress_model.dart';
import '../services/learning_track_progress_service.dart';
import '../services/training_path_progress_service_v2.dart';
import '../services/learning_path_gatekeeper_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_launcher.dart';
import '../services/learning_path_progress_tracker_service.dart';
import '../services/skill_gap_booster_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../widgets/learning_stage_tile.dart';
import 'learning_path_stage_detailed_screen.dart';

/// Displays stages of a learning path with progress indicators.
class LearningPathStageListScreen extends StatefulWidget {
  final LearningPathTemplateV2 path;
  const LearningPathStageListScreen({super.key, required this.path});

  @override
  State<LearningPathStageListScreen> createState() =>
      _LearningPathStageListScreenState();
}

class _LearningPathStageListScreenState
    extends State<LearningPathStageListScreen> {
  late SessionLogService _logs;
  late TrainingPathProgressServiceV2 _progress;
  late LearningPathGatekeeperService _gatekeeper;
  late LearningTrackProgressService _service;
  final _tracker = const LearningPathProgressTrackerService();

  LearningTrackProgressModel _model = const LearningTrackProgressModel(
    stages: [],
  );
  Map<String, String> _progressStrings = {};
  final Map<String, List<TrainingPackTemplateV2>> _boosters = {};
  bool _loading = true;
  bool _initialized = false;
  final Set<String> _openSections = {};

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
      _openSections
        ..clear()
        ..addAll(widget.path.sections.map((s) => s.id));
      _load();
      _initialized = true;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _logs.load();
    final model = await _service.build(widget.path.id);
    final progressStrings = _tracker.computeProgressStrings(
      widget.path,
      _logs.logs,
    );
    final masteryMap = await context.read<TagMasteryService>().computeMastery();
    final boosterService = const SkillGapBoosterService();
    final boosters = <String, List<TrainingPackTemplateV2>>{};
    for (final stage in widget.path.stages) {
      final status = model.statusFor(stage.id)?.status ?? StageStatus.locked;
      if (status == StageStatus.completed) continue;
      final packs = await boosterService.suggestBoosters(
        requiredTags: stage.tags,
        masteryMap: masteryMap,
        count: 3,
      );
      if (packs.isNotEmpty) boosters[stage.id] = packs;
    }
    if (!mounted) return;
    setState(() {
      _model = model;
      _progressStrings = progressStrings;
      _boosters
        ..clear()
        ..addAll(boosters);
      _loading = false;
    });
  }

  Future<void> _openStage(LearningPathStageModel stage) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LearningPathStageDetailedScreen(path: widget.path, stage: stage),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.path.stages;
    final hasSections = widget.path.sections.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(widget.path.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: hasSections
                    ? _buildSectionedList(stages)
                    : [for (final s in stages) _buildStageItem(s)],
              ),
            ),
    );
  }

  List<Widget> _buildSectionedList(List<LearningPathStageModel> stages) {
    final map = {for (final s in stages) s.id: s};
    final list = <Widget>[];
    for (final section in widget.path.sections) {
      final children = <Widget>[];
      for (final id in section.stageIds) {
        final stage = map[id];
        if (stage != null) children.add(_buildStageItem(stage));
      }
      list.add(
        ExpansionTile(
          initiallyExpanded: _openSections.contains(section.id),
          onExpansionChanged: (v) => setState(() {
            if (v) {
              _openSections.add(section.id);
            } else {
              _openSections.remove(section.id);
            }
          }),
          title: Text(section.title),
          subtitle:
              section.description.isNotEmpty ? Text(section.description) : null,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          children: children,
        ),
      );
    }
    return list;
  }

  Widget _buildStageItem(LearningPathStageModel stage) {
    final status = _model.statusFor(stage.id)?.status ?? StageStatus.locked;
    final progress = _progressStrings[stage.id] ?? '';
    final boosters = _boosters[stage.id] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LearningStageTile(
          stage: stage,
          status: status,
          subtitle: progress,
          onTap: () => _openStage(stage),
        ),
        if (boosters.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
              itemBuilder: (context, i) => _buildBoosterCard(boosters[i]),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: boosters.length,
            ),
          ),
      ],
    );
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
}
