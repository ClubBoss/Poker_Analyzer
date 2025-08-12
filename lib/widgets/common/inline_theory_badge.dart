import 'package:flutter/material.dart';

import '../../models/theory_mini_lesson_node.dart';
import '../../screens/theory_lesson_viewer_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/inline_theory_linker_cache.dart';

/// Displays a small badge linking to a relevant theory lesson for given tags.
///
/// The badge is only shown if at least one lesson matches [tags]. Lessons are
/// resolved lazily to avoid upfront loading costs.
class InlineTheoryBadge extends StatefulWidget {
  final List<String> tags;
  final String spotId;
  final String? packId;
  final InlineTheoryLinkerCache cache;

  const InlineTheoryBadge({
    super.key,
    required this.tags,
    required this.spotId,
    this.packId,
    InlineTheoryLinkerCache? cache,
  }) : cache = cache ?? InlineTheoryLinkerCache.instance;

  @override
  State<InlineTheoryBadge> createState() => _InlineTheoryBadgeState();
}

class _InlineTheoryBadgeState extends State<InlineTheoryBadge> {
  List<TheoryMiniLessonNode> _lessons = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.cache.ensureReady();
      final matches = widget.cache.getMatchesForTags(widget.tags);
      if (!mounted) return;
      setState(() {
        _lessons = matches;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _openLesson(TheoryMiniLessonNode lesson) async {
    try {
      await AnalyticsService.instance.logEvent('theory_link_opened', {
        'lesson_id': lesson.id,
        'spot_id': widget.spotId,
        if (widget.packId != null) 'pack_id': widget.packId,
      });
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: TheoryLessonViewerScreen(
            lesson: lesson,
            currentIndex: 1,
            totalCount: 1,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open lesson')),
        );
      }
    }
  }

  Future<void> _handleTap() async {
    final lessons = _lessons;
    if (lessons.isEmpty) return;
    if (lessons.length == 1) {
      await _openLesson(lessons.first);
      return;
    }
    try {
      await AnalyticsService.instance.logEvent('theory_list_opened', {
        'spot_id': widget.spotId,
        if (widget.packId != null) 'pack_id': widget.packId,
        'count': lessons.length,
      });
      await showModalBottomSheet(
        context: context,
        builder: (ctx) => ListView(
          shrinkWrap: true,
          children: [
            for (final l in lessons)
              ListTile(
                title: Text(l.resolvedTitle),
                subtitle: Text(l.tags.join(', ')),
                onTap: () {
                  Navigator.pop(ctx);
                  Future.microtask(() => _openLesson(l));
                },
              ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open lessons')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _lessons.isEmpty) return const SizedBox.shrink();
    final count = _lessons.length;
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: ActionChip(
        avatar: const Icon(Icons.school, size: 16),
        label: Text('Theory • $count'),
        onPressed: _handleTap,
      ),
    );
  }
}
