import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'smart_theory_booster_linker.dart';
import 'booster_fatigue_guard.dart';
import 'theory_recap_analytics_reporter.dart';
import 'smart_booster_dropoff_detector.dart';
import 'smart_theory_recap_dismissal_memory.dart';
import '../screens/theory_cluster_detail_screen.dart';
import '../services/theory_cluster_summary_service.dart';
import '../services/theory_lesson_tag_clusterer.dart';
import '../models/theory_lesson_cluster.dart';

/// Engine that suggests theory recap links at vulnerable moments.
class SmartTheoryRecapEngine {
  final SmartTheoryBoosterLinker linker;
  final SmartBoosterDropoffDetector dropoff;
  final SmartTheoryRecapDismissalMemory dismissalMemory;

  SmartTheoryRecapEngine({
    this.linker = const SmartTheoryBoosterLinker(),
    SmartBoosterDropoffDetector? dropoff,
    SmartTheoryRecapDismissalMemory? dismissalMemory,
  })  : dropoff = dropoff ?? SmartBoosterDropoffDetector.instance,
        dismissalMemory =
            dismissalMemory ?? SmartTheoryRecapDismissalMemory.instance;

  static const _dismissKey = 'smart_theory_recap_dismissed';
  static final SmartTheoryRecapEngine instance = SmartTheoryRecapEngine();

  Future<bool> _recentlyDismissed([
    Duration threshold = const Duration(hours: 12),
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_dismissKey);
    if (str == null) return false;
    final ts = DateTime.tryParse(str);
    if (ts == null) return false;
    return DateTime.now().difference(ts) < threshold;
  }

  Future<void> _markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissKey, DateTime.now().toIso8601String());
  }

  /// Resolves a deep link for [lessonId] or [tags].
  /// Public for testing.
  Future<String?> getLink({String? lessonId, List<String>? tags}) async {
    String? link;
    if (lessonId != null) {
      link = await linker.linkForLesson(lessonId);
    }
    link ??= await linker.linkForTags(tags ?? const []);
    return link;
  }

  Future<void> _openLink(BuildContext context, String link) async {
    final uri = Uri.parse(link);
    if (uri.path != '/theory/cluster') return;
    final clusterId = uri.queryParameters['clusterId'];
    if (clusterId == null || clusterId.isEmpty) return;
    final clusterer = TheoryLessonTagClusterer();
    final clusters = await clusterer.clusterLessons();
    final summarySvc = TheoryClusterSummaryService();
    TheoryLessonCluster? matched;
    for (final c in clusters) {
      final summary = summarySvc.generateSummary(c);
      if (summary.entryPointIds.contains(clusterId)) {
        matched = c;
        break;
      }
    }
    if (matched != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TheoryClusterDetailScreen(cluster: matched!),
        ),
      );
    }
  }

  /// Attempts to show a recap prompt if a relevant link is available.
  Future<void> maybePrompt({
    String? lessonId,
    List<String>? tags,
    String trigger = '',
  }) async {
    if (await dropoff.isInDropoffState()) {
      await TheoryRecapAnalyticsReporter.instance.logEvent(
        lessonId: lessonId ?? '',
        trigger: trigger,
        outcome: 'dropoff',
        delay: null,
      );
      return;
    }
    if (await BoosterFatigueGuard.instance
        .isFatigued(lessonId: lessonId ?? '', trigger: trigger)) {
      return;
    }
    final keys = <String>[];
    if (lessonId != null && lessonId.isNotEmpty) {
      keys.add('lesson:$lessonId');
    } else if (tags != null) {
      keys.addAll(tags.map((t) => 'tag:$t'));
    }
    for (final k in keys) {
      if (await dismissalMemory.shouldThrottle(k)) {
        await TheoryRecapAnalyticsReporter.instance.logEvent(
          lessonId: lessonId ?? '',
          trigger: trigger,
          outcome: 'cooldown',
          delay: null,
        );
        return;
      }
    }
    if (await _recentlyDismissed()) {
      await TheoryRecapAnalyticsReporter.instance.logEvent(
        lessonId: lessonId ?? '',
        trigger: trigger,
        outcome: 'cooldown',
        delay: null,
      );
      return;
    }
    final link = await getLink(lessonId: lessonId, tags: tags);
    if (link == null) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final open = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Want to review related theory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Theory Recap'),
          ),
        ],
      ),
    );
    await _markDismissed();
    if (open == true) {
      await _openLink(ctx, link);
    } else {
      for (final k in keys) {
        unawaited(dismissalMemory.registerDismissal(k));
      }
    }
    await TheoryRecapAnalyticsReporter.instance.logEvent(
      lessonId: lessonId ?? '',
      trigger: trigger,
      outcome: 'shown',
      delay: null,
    );
  }
}
