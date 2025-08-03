import 'package:flutter/material.dart';

import '../models/theory_block_model.dart';
import '../services/theory_path_completion_evaluator_service.dart';
import '../services/user_progress_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/pinned_learning_service.dart';
import '../services/theory_block_launcher.dart';

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
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pinned =
        PinnedLearningService.instance.isPinned('block', widget.block.id);
    PinnedLearningService.instance.addListener(_updatePinned);
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
    await const TheoryBlockLauncher().launch(
      context: context,
      block: widget.block,
      trackId: widget.trackId,
    );
  }

  void _updatePinned() {
    final pinned =
        PinnedLearningService.instance.isPinned('block', widget.block.id);
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  Future<void> _togglePinned() async {
    await PinnedLearningService.instance.toggleBlock(widget.block);
    final pinned =
        PinnedLearningService.instance.isPinned('block', widget.block.id);
    if (mounted) {
      setState(() => _pinned = pinned);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pinned ? 'Pinned' : 'Unpinned')),
      );
    }
  }

  Future<void> _handleLongPress() async {
    final block = widget.block;
    await MiniLessonLibraryService.instance.loadAll();
    final lessons = <_LessonEntry>[];
    for (final id in block.nodeIds) {
      final lesson = MiniLessonLibraryService.instance.getById(id);
      if (lesson == null) continue;
      final done = await widget.progress.isTheoryLessonCompleted(id);
      lessons.add(_LessonEntry(lesson, done));
    }

    final packs = <_PackEntry>[];
    for (final id in block.practicePackIds) {
      final tpl = await PackLibraryService.instance.getById(id);
      if (tpl == null) continue;
      final done = await widget.progress.isPackCompleted(id);
      packs.add(_PackEntry(tpl, done));
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(
                    _pinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(_pinned ? 'Unpin Block' : 'Pin Block'),
                onTap: () async {
                  Navigator.pop(context);
                  await _togglePinned();
                },
              ),
              if (lessons.isNotEmpty)
                const ListTile(title: Text('Lessons')),
              for (final e in lessons)
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(e.lesson.title),
                  trailing: Icon(
                    e.done ? Icons.check_circle : Icons.cancel,
                    color: e.done ? Colors.green : Colors.red,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MiniLessonScreen(
                          lesson: e.lesson,
                        ),
                      ),
                    );
                  },
                ),
              if (packs.isNotEmpty)
                const ListTile(title: Text('Drill Packs')),
              for (final e in packs)
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(e.pack.name),
                  trailing: Icon(
                    e.done ? Icons.check_circle : Icons.cancel,
                    color: e.done ? Colors.green : Colors.red,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackScreen(pack: e.pack),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
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
        child: Stack(
          children: [
            Container(
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
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                    _pinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: _togglePinned,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    PinnedLearningService.instance.removeListener(_updatePinned);
    super.dispose();
  }
}

class _LessonEntry {
  final TheoryMiniLessonNode lesson;
  final bool done;
  _LessonEntry(this.lesson, this.done);
}

class _PackEntry {
  final TrainingPackTemplateV2 pack;
  final bool done;
  _PackEntry(this.pack, this.done);
}
