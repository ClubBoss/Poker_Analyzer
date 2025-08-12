import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/training_spot_attempt.dart';
import '../services/inline_theory_linker_cache.dart';
import '../services/analytics_service.dart';
import '../services/mistake_tag_classifier.dart';
import '../services/theory_suggestion_ranker.dart';
import '../services/last_viewed_theory_store.dart';
import '../services/user_error_rate_service.dart';
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
  final TrainingSpotAttempt attempt;
  final String packId;
  final String spotId;
  final LessonMatchProvider matchProvider;
  final AnalyticsLogger log;
  final void Function(String spotId, String packId, String? lessonId)?
  onTheoryViewed;

  const MistakeInlineTheoryPrompt({
    super.key,
    required this.attempt,
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
  List<RankedTheoryLesson>? _lessons;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final hide = prefs.getBool('hide_theory_prompt_${widget.packId}') ?? false;
    if (hide) return;
    final baseTags = <String>{
      for (final t in widget.attempt.spot.tags) t.toLowerCase(),
    };
    baseTags.addAll(const MistakeTagClassifier()
        .classifyTheory(widget.attempt)
        .map((e) => e.toLowerCase()));
    final matches = await widget.matchProvider(baseTags.toList());
    if (matches.isEmpty) return;
    final rates = await UserErrorRateService.instance.getRates(
      packId: widget.packId,
      tags: baseTags,
    );
    final ranked = await TheorySuggestionRanker(
      userErrorRate: rates,
      packId: widget.packId,
    ).rank(matches);
    await widget.log('theory_suggestion_shown', {
      'packId': widget.packId,
      'spotId': widget.spotId,
      'count': ranked.length,
      'topLessonId': ranked.first.lesson.id,
    });
    setState(() => _lessons = ranked);
  }

  Future<void> _openLesson(RankedTheoryLesson lesson, int total) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TheoryLessonViewerScreen(
          lesson: lesson.lesson,
          currentIndex: 1,
          totalCount: total,
        ),
        fullscreenDialog: true,
      ),
    );
    widget.onTheoryViewed
        ?.call(widget.spotId, widget.packId, lesson.lesson.id);
  }

  Future<void> _open() async {
    final lessons = _lessons!;
    if (lessons.length == 1) {
      final l = lessons.first;
      await widget.log('theory_link_opened', {
        'packId': widget.packId,
        'spotId': widget.spotId,
        'rank_score': l.score,
      });
      await LastViewedTheoryStore.instance.add(widget.packId, l.lesson.id);
      await _openLesson(l, lessons.length);
      return;
    }
    await widget.log('theory_list_opened', {
      'packId': widget.packId,
      'spotId': widget.spotId,
      'count': lessons.length,
    });
    final selected = await showModalBottomSheet<RankedTheoryLesson>(
      context: context,
      builder: (_) => ListView(
        children: [
          for (var i = 0; i < lessons.length; i++)
            ListTile(
              title: Text(lessons[i].lesson.resolvedTitle),
              subtitle: Text(lessons[i].lesson.tags.join(', ')),
              trailing:
                  i == 0 ? const _TopBadge() : null,
              onTap: () => Navigator.pop(context, lessons[i]),
            ),
        ],
      ),
    );
    if (selected != null) {
      await widget.log('theory_link_opened', {
        'packId': widget.packId,
        'spotId': widget.spotId,
        'rank_score': selected.score,
      });
      await LastViewedTheoryStore.instance
          .add(widget.packId, selected.lesson.id);
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

class _TopBadge extends StatelessWidget {
  const _TopBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Top',
        style: TextStyle(fontSize: 10, color: Colors.black),
      ),
    );
  }
}
