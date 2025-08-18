import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_track.dart';
import '../models/v3/lesson_step.dart';
import '../models/v3/track_meta.dart';
import '../services/learning_track_engine.dart';
import '../services/lesson_loader_service.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/lesson_progress_tracker_service.dart';
import '../services/lesson_track_meta_service.dart';
import '../services/learning_path_completion_service.dart';
import '../models/mastery_level.dart';
import '../services/mastery_level_engine.dart';
import '../widgets/goal_dashboard_widget.dart';
import '../widgets/xp_level_bar.dart';
import '../widgets/next_up_widget.dart';
import '../services/xp_reward_engine.dart';
import '../services/lesson_path_reminder_scheduler.dart';
import 'master_mode_screen.dart';
import 'lesson_step_screen.dart';
import 'lesson_step_recap_screen.dart';

class TrackProgressDashboardScreen extends StatefulWidget {
  const TrackProgressDashboardScreen({super.key});

  @override
  State<TrackProgressDashboardScreen> createState() =>
      _TrackProgressDashboardScreenState();
}

class _TrackProgressDashboardScreenState
    extends State<TrackProgressDashboardScreen> {
  late Future<Map<String, dynamic>> _future;
  late Future<MasteryLevel> _levelFuture;
  bool _bannerShown = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _future = _load();
    _levelFuture = MasteryLevelEngine().computeUserLevel();
    LessonPathReminderScheduler.instance.getScheduledTime().then((t) {
      if (!mounted) return;
      if (t != null) {
        setState(() {
          _reminderEnabled = true;
          _reminderTime = t;
        });
      }
    });
  }

  Future<Map<String, dynamic>> _load() async {
    final tracks = const LearningTrackEngine().getTracks();
    final progress = await LessonPathProgressService.instance
        .computeTrackProgress();
    final completed = await LessonProgressTrackerService.instance
        .getCompletedStepsFlat();
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final Map<String, TrackMeta?> meta = {};
    for (final t in tracks) {
      var m = await LessonTrackMetaService.instance.load(t.id);
      final percent = progress[t.id] ?? 0.0;
      if (percent > 0 && (m?.startedAt == null)) {
        await LessonTrackMetaService.instance.markStarted(t.id);
        m = await LessonTrackMetaService.instance.load(t.id);
      }
      if (percent >= 100 && (m?.completedAt == null)) {
        await LessonTrackMetaService.instance.markCompleted(t.id);
        m = await LessonTrackMetaService.instance.load(t.id);
      }
      meta[t.id] = m;
    }
    final allCompleted = progress.values.every((p) => p >= 100);
    if (allCompleted) {
      await LearningPathCompletionService.instance.markPathCompleted();
    }
    final pathCompleted = await LearningPathCompletionService.instance
        .isPathCompleted();
    final totalXp = await XPRewardEngine.instance.getTotalXp();
    final level = getLevel(totalXp);
    final levelXp = getXpForNextLevel(totalXp);
    return {
      'tracks': tracks,
      'progress': progress,
      'completed': completed,
      'steps': steps,
      'meta': meta,
      'pathCompleted': pathCompleted,
      'totalXp': totalXp,
      'level': level,
      'levelXp': levelXp,
    };
  }

  Future<void> _continueTrack(
    LessonTrack track,
    Map<String, bool> completed,
    List<LessonStep> steps,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lesson_selected_track', track.id);
    final id = track.stepIds.firstWhere(
      (e) => completed[e] != true,
      orElse: () => track.stepIds.last,
    );
    final step = steps.firstWhereOrNull((s) => s.id == id);
    if (!mounted || step == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: step,
          onStepComplete: (s) async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonStepRecapScreen(step: s)),
            );
          },
        ),
      ),
    );
  }

  String _daysAgo(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days <= 0) return 'сегодня';
    if (days == 1) return '1 день назад';
    return '$days дней назад';
  }

  Color _levelColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.beginner:
        return Colors.redAccent;
      case MasteryLevel.intermediate:
        return Colors.orangeAccent;
      case MasteryLevel.expert:
        return Colors.greenAccent;
    }
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      await LessonPathReminderScheduler.instance.scheduleReminder(
        time: _reminderTime,
      );
    } else {
      await LessonPathReminderScheduler.instance.cancelReminder();
    }
    if (mounted) {
      setState(() => _reminderEnabled = value);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      await LessonPathReminderScheduler.instance.scheduleReminder(time: picked);
      if (mounted) {
        setState(() {
          _reminderEnabled = true;
          _reminderTime = picked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final tracks = data?['tracks'] as List<LessonTrack>? ?? [];
        final progress = data?['progress'] as Map<String, double>? ?? {};
        final completed = data?['completed'] as Map<String, bool>? ?? {};
        final steps = data?['steps'] as List<LessonStep>? ?? [];
        final meta = data?['meta'] as Map<String, TrackMeta?>? ?? {};
        final pathCompleted = data?['pathCompleted'] == true;

        if (pathCompleted && !_bannerShown) {
          _bannerShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearMaterialBanners();
            messenger.showMaterialBanner(
              MaterialBanner(
                content: const Text('🎉 Вы завершили адаптивный путь'),
                actions: [
                  TextButton(
                    onPressed: messenger.hideCurrentMaterialBanner,
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            );
            Future.delayed(const Duration(seconds: 4), () {
              messenger.hideCurrentMaterialBanner();
            });
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Прогресс треков')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : tracks.isEmpty
              ? const Center(
                  child: Text(
                    'Нет треков',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Column(
                  children: [
                    const GoalDashboardWidget(),
                    XPLevelBar(
                      currentXp: data?['totalXp'] as int? ?? 0,
                      levelXp: data?['levelXp'] as int? ?? 0,
                      level: data?['level'] as int? ?? 1,
                    ),
                    const NextUpWidget(),
                    SwitchListTile(
                      value: _reminderEnabled,
                      activeColor: Colors.orange,
                      title: const Text(
                        '⏰ Ежедневное напоминание',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Время: ${_reminderTime.format(context)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onChanged: _toggleReminder,
                    ),
                    if (_reminderEnabled)
                      ListTile(
                        title: const Text(
                          'Изменить время',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          _reminderTime.format(context),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: _pickReminderTime,
                      ),
                    FutureBuilder<MasteryLevel>(
                      future: _levelFuture,
                      builder: (context, levelSnap) {
                        if (levelSnap.connectionState != ConnectionState.done) {
                          return const SizedBox.shrink();
                        }
                        final level = levelSnap.data;
                        if (level == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '🔰 Уровень: ${level.label}',
                            style: TextStyle(
                              color: _levelColor(level),
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final percent = progress[track.id] ?? 0.0;
                          final total = track.stepIds.length;
                          final done = track.stepIds
                              .where((id) => completed[id] == true)
                              .length;
                          final trackMeta = meta[track.id];
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(track.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$done / $total шагов, ${percent.round()}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percent / 100,
                                    color: Colors.orange,
                                    backgroundColor: Colors.white24,
                                  ),
                                  if (trackMeta != null &&
                                      trackMeta.startedAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '🟢 Начато: ${_daysAgo(trackMeta.startedAt!)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (trackMeta.completedAt != null)
                                      Text(
                                        '🏁 Завершено: ${_daysAgo(trackMeta.completedAt!)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    Text(
                                      '🔁 Пройдено: ${trackMeta.timesCompleted} раз',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () =>
                                    _continueTrack(track, completed, steps),
                                child: const Text('Продолжить путь'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    FutureBuilder<MasteryLevel>(
                      future: _levelFuture,
                      builder: (context, levelSnap) {
                        if (levelSnap.connectionState != ConnectionState.done) {
                          return const SizedBox.shrink();
                        }
                        final level = levelSnap.data;
                        final show =
                            pathCompleted && level == MasteryLevel.expert;
                        if (!show) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              MasterModeScreen.route,
                            ),
                            child: const Text('🔥 Мастер-режим'),
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
}
