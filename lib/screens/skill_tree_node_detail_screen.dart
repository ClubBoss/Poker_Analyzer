import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/skill_tree.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/skill_tree_category_banner_service.dart';
import '../services/skill_tree_node_progress_tracker.dart';
import '../services/training_progress_service.dart';
import '../services/skill_tree_node_celebration_service.dart';
import '../services/learning_path_entry_group_builder.dart';
import '../services/learning_path_node_renderer_service.dart';
import '../widgets/tag_badge.dart';
import '../widgets/skill_tree_node_detail_hint_widget.dart';
import 'theory_lesson_viewer_screen.dart';

/// Screen showing details for a [SkillTreeNodeModel] before starting it.
class SkillTreeNodeDetailScreen extends StatefulWidget {
  final SkillTreeNodeModel node;
  final bool unlocked;
  final SkillTree? track;
  final Set<String>? unlockedNodeIds;
  final Set<String>? completedNodeIds;

  const SkillTreeNodeDetailScreen({
    super.key,
    required this.node,
    this.unlocked = true,
    this.track,
    this.unlockedNodeIds,
    this.completedNodeIds,
  });

  @override
  State<SkillTreeNodeDetailScreen> createState() =>
      _SkillTreeNodeDetailScreenState();
}

class _SkillTreeNodeDetailScreenState extends State<SkillTreeNodeDetailScreen> {
  TheoryMiniLessonNode? _lesson;
  double _progress = 0.0;
  bool _loading = true;
  List<LearningPathEntryGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.node.theoryLessonId.isNotEmpty) {
      await MiniLessonLibraryService.instance.loadAll();
      _lesson =
          MiniLessonLibraryService.instance.getById(widget.node.theoryLessonId);
    }
    if (widget.node.trainingPackId.isNotEmpty) {
      _progress = await TrainingProgressService.instance
          .getProgress(widget.node.trainingPackId);
    } else {
      final done = await SkillTreeNodeProgressTracker.instance
          .isCompleted(widget.node.id);
      if (done) _progress = 1.0;
    }
    _groups = await LearningPathEntryGroupBuilder().build(widget.node);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _start() async {
    final wasComplete = _progress >= 1.0;
    if (widget.node.theoryLessonId.isNotEmpty) {
      final lesson = _lesson;
      if (lesson == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TheoryLessonViewerScreen(
            lesson: lesson,
            currentIndex: 1,
            totalCount: 1,
          ),
        ),
      );
    } else if (widget.node.trainingPackId.isNotEmpty) {
      final tpl =
          await PackLibraryService.instance.getById(widget.node.trainingPackId);
      if (tpl != null) {
        await const TrainingSessionLauncher().launch(tpl);
      }
    }
    await _load();
    if (mounted && !wasComplete && _progress >= 1.0) {
      await SkillTreeNodeCelebrationService().maybeCelebrate(
        context,
        widget.node.id,
        trackId: widget.node.category,
        stage: widget.node.level,
      );
    }
  }

  String _shortDescription(String text, {int max = 160}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }

  @override
  Widget build(BuildContext context) {
    final visual =
        const SkillTreeCategoryBannerService().getVisual(widget.node.category);
    final accent = visual.color;
    final pct = (_progress.clamp(0.0, 1.0) * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text(widget.node.title)),
      backgroundColor: const Color(0xFF121212),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(visual.emoji,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.node.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_lesson != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _lesson!.resolvedTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_lesson!.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: -4,
                            children: [
                              for (final t in _lesson!.tags.take(3)) TagBadge(t)
                            ],
                          ),
                        ),
                      if (_lesson!.resolvedContent.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _shortDescription(_lesson!.resolvedContent),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$pct%',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    if (!widget.unlocked &&
                        widget.track != null &&
                        widget.unlockedNodeIds != null &&
                        widget.completedNodeIds != null)
                      SkillTreeNodeDetailHintWidget(
                        node: widget.node,
                        track: widget.track!,
                        unlocked: widget.unlockedNodeIds!,
                        completed: widget.completedNodeIds!,
                      ),
                    if (_groups.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: LearningPathNodeRendererService()
                            .build(context, _groups),
                      ),
                    const Spacer(),
                    Tooltip(
                      message:
                          widget.unlocked ? '' : 'Этап ещё не разблокирован',
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.unlocked ? _start : null,
                          style:
                              ElevatedButton.styleFrom(backgroundColor: accent),
                          child: const Text('Начать'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
