import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_track_progress_model.dart';
import '../services/training_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/unlock_condition_evaluator.dart';
import '../screens/v2/training_pack_play_screen.dart';
import '../models/sub_stage_model.dart';
import 'tag_badge.dart';

/// Tile representing a stage of a learning path.
class LearningStageTile extends StatefulWidget {
  final LearningPathStageModel stage;
  final StageStatus status;
  final String subtitle;
  final VoidCallback? onTap;

  const LearningStageTile({
    super.key,
    required this.stage,
    required this.status,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<LearningStageTile> createState() => _LearningStageTileState();
}

class _LearningStageTileState extends State<LearningStageTile> {
  final Map<String, double> _progress = {};
  final Map<String, double> _accuracy = {};
  final UnlockConditionEvaluator _evaluator = const UnlockConditionEvaluator();
  bool _loading = false;
  String? _lastStartedId;

  String? _computeLastStarted() {
    String? id;
    double last = 0.0;
    for (final entry in _progress.entries) {
      final prog = entry.value;
      if (prog > 0 && prog < 1.0 && prog >= last) {
        last = prog;
        id = entry.key;
      }
    }
    return id;
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    _lastStartedId = null;
    for (final s in widget.stage.subStages) {
      final prog = await TrainingProgressService.instance.getSubStageProgress(
        widget.stage.id,
        s.packId,
      );
      _progress[s.packId] = prog;
      final stat = await TrainingPackStatsService.getStats(s.packId);
      _accuracy[s.packId] = (stat?.accuracy ?? 0.0) * 100;
    }
    _lastStartedId = _computeLastStarted();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final locked = widget.status == StageStatus.locked;
    final completed = widget.status == StageStatus.completed;

    Widget trailing;
    if (completed) {
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    } else if (locked) {
      trailing = const Icon(Icons.lock, color: Colors.grey);
    } else {
      trailing = ElevatedButton(
        onPressed: widget.onTap,
        child: const Text('Начать'),
      );
    }

    final grey = locked ? Colors.white60 : null;

    if (stage.subStages.isEmpty) {
      return Card(
        color: locked ? Colors.grey.shade800 : null,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          title: Text(stage.title, style: TextStyle(color: grey)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stage.description.isNotEmpty)
                Text(stage.description, style: TextStyle(color: grey)),
              Text(
                widget.subtitle,
                style: TextStyle(color: grey, fontSize: 12),
              ),
              if (stage.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: -4,
                    children: [for (final t in stage.tags.take(3)) TagBadge(t)],
                  ),
                ),
            ],
          ),
          trailing: trailing,
          onTap: locked ? null : widget.onTap,
        ),
      );
    } else {
      final avgProg = _progress.isEmpty
          ? 0.0
          : _progress.values.fold(0.0, (a, b) => a + b) /
              stage.subStages.length;
      final children = _loading
          ? const [
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ]
          : [for (final s in stage.subStages) _buildSubStageTile(s)];
      return Card(
        color: locked ? Colors.grey.shade800 : null,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ExpansionTile(
          initiallyExpanded: !completed,
          onExpansionChanged: (v) {
            if (v && _progress.isEmpty) _load();
          },
          title: Row(
            children: [
              Expanded(
                child: Text(stage.title, style: TextStyle(color: grey)),
              ),
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(value: avgProg),
              ),
            ],
          ),
          subtitle: stage.description.isNotEmpty
              ? Text(stage.description, style: TextStyle(color: grey))
              : null,
          children: children,
        ),
      );
    }
  }

  Widget _buildSubStageTile(SubStageModel sub) {
    final prog = _progress[sub.packId] ?? 0.0;
    final done = prog >= 1.0;
    final highlight = sub.packId == _lastStartedId;
    final unlocked = _evaluator.isUnlocked(
      sub.unlockCondition,
      _progress,
      _accuracy,
    );
    final grey = unlocked ? null : Colors.white60;
    Widget trailing;
    if (!unlocked) {
      trailing = const Icon(Icons.lock, color: Colors.grey);
    } else if (done) {
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    } else {
      trailing = SizedBox(
        width: 80,
        child: LinearProgressIndicator(value: prog),
      );
    }
    return ListTile(
      tileColor: highlight ? Colors.blue.withValues(alpha: 0.1) : null,
      title: Text(sub.title, style: TextStyle(color: grey)),
      subtitle: sub.description.isNotEmpty
          ? Text(sub.description, style: TextStyle(color: grey))
          : null,
      trailing: trailing,
      onTap: !unlocked
          ? null
          : () async {
              final tplId = TrainingPackTemplateService.hasTemplate(sub.packId)
                  ? sub.packId
                  : widget.stage.packId;
              final tpl = TrainingPackTemplateService.getById(tplId, context);
              if (tpl == null) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TrainingPackPlayScreen(template: tpl, original: tpl),
                ),
              );
              final updated = await TrainingProgressService.instance
                  .getSubStageProgress(widget.stage.id, sub.packId);
              setState(() {
                _progress[sub.packId] = updated;
                _lastStartedId = _computeLastStarted();
              });
            },
    );
  }
}
