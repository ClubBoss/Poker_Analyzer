import 'package:flutter/material.dart';

import '../models/theory_block_model.dart';
import '../services/theory_path_completion_evaluator_service.dart';
import '../services/user_progress_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/theory_track_resume_service.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';

/// Card widget displaying a [TheoryBlockModel] with completion progress.
class TheoryBlockCardWidget extends StatefulWidget {
  final TheoryBlockModel block;
  final TheoryPathCompletionEvaluatorService evaluator;
  final UserProgressService progress;
  final String? trackId;

  const TheoryBlockCardWidget({
    super.key,
    required this.block,
    required this.evaluator,
    required this.progress,
    this.trackId,
  });

  @override
  State<TheoryBlockCardWidget> createState() => _TheoryBlockCardWidgetState();
}

class _TheoryBlockCardWidgetState extends State<TheoryBlockCardWidget> {
  double? _percent;
  CompletionStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pct =
        await widget.evaluator.getBlockCompletionPercent(widget.block);
    final status = await widget.evaluator.getBlockStatus(widget.block);
    if (mounted) {
      setState(() {
        _percent = pct;
        _status = status;
      });
    }
  }

  Color _borderColor(BuildContext context, CompletionStatus status) {
    switch (status) {
      case CompletionStatus.completed:
        return Colors.green;
      case CompletionStatus.inProgress:
        return Theme.of(context).colorScheme.secondary;
      case CompletionStatus.notStarted:
      default:
        return Colors.transparent;
    }
  }

  String _labelFor(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.completed:
        return 'Completed';
      case CompletionStatus.inProgress:
        return 'In Progress';
      case CompletionStatus.notStarted:
      default:
        return 'Not Started';
    }
  }

  Future<void> _handleTap() async {
    final block = widget.block;
    final trackId = widget.trackId;
    if (trackId != null) {
      await TheoryTrackResumeService.instance
          .saveLastVisitedBlock(trackId, block.id);
    }
    await MiniLessonLibraryService.instance.loadAll();
    for (final id in block.nodeIds) {
      final done = await widget.progress.isTheoryLessonCompleted(id);
      if (!done) {
        final lesson = MiniLessonLibraryService.instance.getById(id);
        if (lesson != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MiniLessonScreen(lesson: lesson),
            ),
          );
        }
        return;
      }
    }
    for (final id in block.practicePackIds) {
      final done = await widget.progress.isPackCompleted(id);
      if (!done) {
        final tpl = await PackLibraryService.instance.getById(id);
        if (tpl != null) {
          await const TrainingSessionLauncher().launch(tpl);
        }
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Block Completed')),
      );
    }
  }

  Future<void> _handleLongPress() async {
    final block = widget.block;
    await MiniLessonLibraryService.instance.loadAll();
    final tiles = <Widget>[];

    for (final id in block.nodeIds) {
      final lesson = MiniLessonLibraryService.instance.getById(id);
      if (lesson == null) continue;
      final done = await widget.progress.isTheoryLessonCompleted(id);
      tiles.add(
        ListTile(
          leading: const Text('📘', style: TextStyle(fontSize: 20)),
          title: Text(lesson.title),
          trailing: Icon(
            done ? Icons.check_circle : Icons.cancel,
            color: done ? Colors.green : Colors.red,
          ),
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MiniLessonScreen(lesson: lesson),
              ),
            );
          },
        ),
      );
    }

    for (final id in block.practicePackIds) {
      final tpl = await PackLibraryService.instance.getById(id);
      if (tpl == null) continue;
      final done = await widget.progress.isPackCompleted(id);
      tiles.add(
        ListTile(
          leading: const Text('🎯', style: TextStyle(fontSize: 20)),
          title: Text(tpl.name),
          trailing: Icon(
            done ? Icons.check_circle : Icons.cancel,
            color: done ? Colors.green : Colors.red,
          ),
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrainingPackScreen(pack: tpl),
              ),
            );
          },
        ),
      );
    }

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: tiles,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = _percent;
    final status = _status;
    if (percent == null || status == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final border = _borderColor(context, status);
    final label = _labelFor(status);
    final accent = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.block.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        border == Colors.transparent ? accent : border),
                    strokeWidth: 4,
                  ),
                  Text(
                    '${(percent.clamp(0.0, 1.0) * 100).round()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
