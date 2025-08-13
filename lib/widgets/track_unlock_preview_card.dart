import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import '../models/v3/lesson_track.dart';
import '../services/learning_path_unlock_engine.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/lesson_goal_streak_engine.dart';
import '../screens/lesson_track_library_screen.dart';

class TrackUnlockPreviewCard extends StatefulWidget {
  const TrackUnlockPreviewCard({super.key});

  @override
  State<TrackUnlockPreviewCard> createState() => _TrackUnlockPreviewCardState();
}

class _PreviewInfo {
  final LessonTrack track;
  final int met;
  final int total;
  final String? label;

  _PreviewInfo(this.track, this.met, this.total, this.label);
}

class _TrackUnlockPreviewCardState extends State<TrackUnlockPreviewCard> {
  late Future<List<_PreviewInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_PreviewInfo>> _load() async {
    final engine = LearningPathUnlockEngine.instance;
    final builtIn = engine.trackEngine.getTracks();
    final yaml = await engine.yamlLoader.loadTracksFromAssets();
    final tracks = [...builtIn, ...yaml];

    final mastery = await engine.masteryService.computeTrackMastery();
    final streak = await engine.streakEngine.getCurrentStreak();
    final goalStreak = await LessonGoalStreakEngine.instance.getCurrentStreak();
    final progress =
        await LessonPathProgressService.instance.computeTrackProgress();

    final titles = {for (var t in tracks) t.id: t.title};

    final List<_PreviewInfo> res = [];
    for (final t in tracks) {
      if (await engine.canUnlockTrack(t.id)) continue;

      final prereqIds = engine.prereqMap[t.id];
      var prereqMet = true;
      if (prereqIds != null) {
        for (final id in prereqIds) {
          final meta = await engine.metaService.load(id);
          if (meta?.completedAt == null) {
            prereqMet = false;
            break;
          }
        }
      }
      if (!prereqMet) continue;

      final masteryReq = engine.masteryRequirementsMap[t.id];
      var masteryMet = true;
      var masteryNear = false;
      String? label;
      if (masteryReq != null) {
        for (final e in masteryReq.entries) {
          final val = mastery[e.key] ?? 0.0;
          final req = e.value;
          if (val < req) {
            masteryMet = false;
            masteryNear = val >= req * 0.8;
            if (masteryNear) label = 'Нужно добить ${titles[e.key] ?? e.key}';
            break;
          }
        }
      }

      final streakReq = engine.streakRequirementsMap[t.id];
      var streakMet = true;
      var streakNear = false;
      if (streakReq != null) {
        if (streak < streakReq) {
          streakMet = false;
          streakNear = streak == streakReq - 1;
          if (streakNear) label = 'Остался 1 день стрика';
        }
      }

      final goalReq = engine.goalRequirementsMap[t.id];
      var goalMet = true;
      var goalNear = false;
      if (goalReq != null) {
        if (goalStreak < goalReq) {
          goalMet = false;
          goalNear = goalStreak == goalReq - 1;
          if (goalNear) label = 'Нужно выполнить цель ещё один день';
        }
      }

      final total = [
        if (prereqIds != null) 1,
        if (masteryReq != null) 1,
        if (streakReq != null) 1,
        if (goalReq != null) 1,
      ].length;
      final met = [
        if (prereqIds != null && prereqMet) 1,
        if (masteryReq != null && masteryMet) 1,
        if (streakReq != null && streakMet) 1,
        if (goalReq != null && goalMet) 1,
      ].length;

      final near = (masteryNear || streakNear || goalNear) && met < total;
      if (near) {
        res.add(_PreviewInfo(t, met, total, label));
      }
    }

    res.sort((a, b) =>
        (progress[b.track.id] ?? 0).compareTo(progress[a.track.id] ?? 0));
    return res.take(3).toList();
  }

  void _openLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LessonTrackLibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<_PreviewInfo>>(
      future: _future,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (snapshot.connectionState != ConnectionState.done || list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Скоро откроется',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final info = list[i];
                    final pct = info.total == 0 ? 0.0 : info.met / info.total;
                    return Container(
                      width: 200,
                      padding: kCardPadding,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.track.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct,
                            color: accent,
                            backgroundColor: Colors.white24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${info.met}/${info.total} условий',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (info.label != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                info.label!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: _openLibrary,
                              child: const Text('Разблокировать скоро'),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: list.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
