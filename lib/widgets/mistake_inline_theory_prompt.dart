import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/inline_theory_linker_cache.dart';
import '../services/analytics_service.dart';
import '../screens/theory_lesson_viewer_screen.dart';

typedef LessonMatchProvider =
    Future<List<TheoryMiniLessonNode>> Function(List<String> tags);
typedef AnalyticsLogger =
    Future<void> Function(String event, Map<String, dynamic> params);

Future<List<TheoryMiniLessonNode>> _defaultMatchProvider(
  List<String> tags,
) async {
  final cache = InlineTheoryLinkerCache.instance;
  await cache.ensureReady();
  return cache.getMatchesForTags(tags);
}

Future<void> _defaultLog(String event, Map<String, dynamic> params) {
  return AnalyticsService.instance.logEvent(event, params);
}

class MistakeInlineTheoryPrompt extends StatefulWidget {
  final List<String> tags;
  final String packId;
  final String spotId;
  final LessonMatchProvider matchProvider;
  final AnalyticsLogger log;
  final void Function(String spotId, String packId, String? lessonId)?
  onTheoryViewed;

  const MistakeInlineTheoryPrompt({
    super.key,
    required this.tags,
    required this.packId,
    required this.spotId,
    LessonMatchProvider? matchProvider,
    AnalyticsLogger? log,
    this.onTheoryViewed,
  }) : matchProvider = matchProvider ?? _defaultMatchProvider,
       log = log ?? _defaultLog;

  @override
  State<MistakeInlineTheoryPrompt> createState() =>
      _MistakeInlineTheoryPromptState();
}

class _MistakeInlineTheoryPromptState extends State<MistakeInlineTheoryPrompt> {
  List<TheoryMiniLessonNode>? _lessons;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final hide = prefs.getBool('hide_theory_prompt_${widget.packId}') ?? false;
    if (hide) return;
    final matches = await widget.matchProvider(widget.tags);
    if (matches.isEmpty) return;
    await widget.log('theory_suggested_after_mistake', {
      'packId': widget.packId,
      'spotId': widget.spotId,
      'count': matches.length,
    });
    setState(() => _lessons = matches);
  }

  Future<void> _openLesson(TheoryMiniLessonNode lesson, int total) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TheoryLessonViewerScreen(
          lesson: lesson,
          currentIndex: 1,
          totalCount: total,
        ),
        fullscreenDialog: true,
      ),
    );
    widget.onTheoryViewed?.call(widget.spotId, widget.packId, lesson.id);
  }

  Future<void> _open() async {
    final lessons = _lessons!;
    if (lessons.length == 1) {
      await widget.log('theory_link_opened', {
        'packId': widget.packId,
        'spotId': widget.spotId,
      });
      await _openLesson(lessons.first, lessons.length);
      return;
    }
    await widget.log('theory_list_opened', {
      'packId': widget.packId,
      'spotId': widget.spotId,
      'count': lessons.length,
    });
    final selected = await showModalBottomSheet<TheoryMiniLessonNode>(
      context: context,
      builder: (_) => ListView(
        children: [
          for (final l in lessons)
            ListTile(
              title: Text(l.resolvedTitle),
              subtitle: Text(l.tags.join(', ')),
              onTap: () => Navigator.pop(context, l),
            ),
        ],
      ),
    );
    if (selected != null) {
      await widget.log('theory_link_opened', {
        'packId': widget.packId,
        'spotId': widget.spotId,
      });
      await _openLesson(selected, lessons.length);
    }
  }

  Future<void> _disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_theory_prompt_${widget.packId}', true);
    setState(() => _lessons = null);
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    if (lessons == null) return const SizedBox.shrink();
    return Row(
      children: [
        ActionChip(
          avatar: const Icon(Icons.school, size: 16),
          label: Text('Learn now (Theory • ${lessons.length})'),
          onPressed: _open,
        ),
        TextButton(
          onPressed: _disable,
          child: const Text("Don't show for this pack"),
        ),
      ],
    );
  }
}
