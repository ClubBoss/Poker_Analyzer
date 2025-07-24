import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_track_progress_model.dart';
import '../services/training_progress_service.dart';
import '../models/learning_path_sub_stage.dart';
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
  bool _loading = false;

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    for (final s in widget.stage.subStages) {
      final prog =
          await TrainingProgressService.instance.getProgress(s.packId);
      _progress[s.packId] = prog;
    }
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
              Text(widget.subtitle, style: TextStyle(color: grey, fontSize: 12)),
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
              )
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
              Expanded(child: Text(stage.title, style: TextStyle(color: grey))),
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

  Widget _buildSubStageTile(LearningPathSubStage sub) {
    final prog = _progress[sub.packId] ?? 0.0;
    final percent = (prog * 100).round();
    final buttonLabel = prog == 0
        ? 'Начать'
        : (prog >= 1.0 ? 'Повторить' : 'Продолжить');
    return ListTile(
      title: Text(sub.title),
      subtitle: Text('$percent%'),
      trailing: ElevatedButton(
        onPressed:
            widget.status == StageStatus.locked ? null : widget.onTap,
        child: Text(buttonLabel),
      ),
    );
  }
}

