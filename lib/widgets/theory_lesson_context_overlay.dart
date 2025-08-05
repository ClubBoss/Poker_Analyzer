import 'package:flutter/material.dart';

import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/mini_lesson_progress_tracker.dart';
import '../services/theory_lesson_graph_navigator_service.dart';
import '../services/theory_lesson_review_queue.dart';
import '../screens/theory_lesson_viewer_screen.dart';

/// Contextual overlay shown at the bottom of a theory mini lesson.
class TheoryLessonContextOverlay extends StatefulWidget {
  /// Currently viewed lesson id.
  final String lessonId;

  /// Optional cluster to compute progress and sibling lessons.
  final TheoryLessonCluster? cluster;

  /// Optional tag filter for review suggestions.
  final Set<String> tags;

  /// Whether the lesson is already complete. If null it will be
  /// resolved from [MiniLessonProgressTracker].
  final bool? isComplete;

  /// Number of mistakes related to this lesson.
  final int? mistakeCount;

  /// Optional services for testing.
  final MiniLessonLibraryService? library;
  final MiniLessonProgressTracker? progress;
  final TheoryLessonReviewQueue? review;

  const TheoryLessonContextOverlay({
    super.key,
    required this.lessonId,
    this.cluster,
    this.tags = const {},
    this.isComplete,
    this.mistakeCount,
    this.library,
    this.progress,
    this.review,
  });

  @override
  State<TheoryLessonContextOverlay> createState() =>
      _TheoryLessonContextOverlayState();
}

class _TheoryLessonContextOverlayState
    extends State<TheoryLessonContextOverlay> {
  late final MiniLessonLibraryService _library;
  late final MiniLessonProgressTracker _progress;
  late final TheoryLessonReviewQueue _review;
  late final TheoryLessonGraphNavigatorService _nav;

  bool _loading = true;
  int _completed = 0;
  int _total = 0;
  TheoryMiniLessonNode? _next;
  TheoryMiniLessonNode? _prev;
  List<TheoryMiniLessonNode> _siblings = [];
  bool _hasWeakReviews = false;

  @override
  void initState() {
    super.initState();
    _library = widget.library ?? MiniLessonLibraryService.instance;
    _progress = widget.progress ?? MiniLessonProgressTracker.instance;
    _review = widget.review ?? TheoryLessonReviewQueue.instance;
    _nav = TheoryLessonGraphNavigatorService(
      library: _library,
      cluster: widget.cluster,
      tagFilter: widget.tags,
    );
    _load();
  }

  Future<void> _load() async {
    await _nav.initialize();
    _next = _nav.getNext(widget.lessonId);
    _prev = _nav.getPrevious(widget.lessonId);
    _siblings = _nav.getSiblings(widget.lessonId);

    if (widget.cluster != null) {
      _total = widget.cluster!.lessons.length;
      for (final l in widget.cluster!.lessons) {
        if (await _progress.isCompleted(l.id)) _completed++;
      }
    }

    if (widget.tags.isNotEmpty) {
      final items = await _review.getNextLessonsToReview(
        focusTags: widget.tags,
        limit: 1,
      );
      _hasWeakReviews = items.isNotEmpty;
    } else if ((widget.mistakeCount ?? 0) > 0) {
      _hasWeakReviews = true;
    }

    setState(() => _loading = false);
  }

  bool get _hasActions =>
      _next != null || _prev != null || _hasWeakReviews || _total > 0;

  void _openLesson(TheoryMiniLessonNode lesson) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonViewerScreen(
          lesson: lesson,
          currentIndex: 1,
          totalCount: 1,
        ),
      ),
    );
  }

  void _retry() {
    final lesson = _library.getById(widget.lessonId);
    if (lesson != null) _openLesson(lesson);
  }

  void _reviewWeak() async {
    final items = await _review.getNextLessonsToReview(
      focusTags: widget.tags,
      limit: 1,
    );
    if (items.isNotEmpty) _openLesson(items.first);
  }

  void _showSiblings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          for (final l in _siblings)
            ListTile(
              title: Text(l.resolvedTitle),
              onTap: () {
                Navigator.pop(context);
                _openLesson(l);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_hasActions) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_total > 0)
                Text(
                  '$_completed of $_total complete',
                  style: const TextStyle(color: Colors.white70),
                ),
              if (_siblings.isNotEmpty)
                TextButton(
                  onPressed: _showSiblings,
                  child: Text('See similar (${_siblings.length})'),
                ),
              Row(
                children: [
                  if (_prev != null)
                    OutlinedButton(
                      onPressed: () => _openLesson(_prev!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent),
                      ),
                      child: const Text('Go Back'),
                    ),
                  if (_next != null) ...[
                    if (_prev != null) const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _openLesson(_next!),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Next'),
                    ),
                  ],
                  if (_next == null && _prev == null) ...[
                    ElevatedButton(
                      onPressed: _retry,
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Retry'),
                    ),
                  ],
                  const Spacer(),
                  if (_hasWeakReviews)
                    TextButton(
                      onPressed: _reviewWeak,
                      child: const Text('Review Weak Spots'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
