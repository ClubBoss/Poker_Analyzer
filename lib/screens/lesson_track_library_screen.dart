import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_track.dart';
import '../models/player_profile.dart';
import '../services/learning_track_engine.dart';
import '../services/yaml_lesson_track_loader.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/track_visibility_filter_engine.dart';
import '../services/track_unlock_reason_service.dart';
import '../services/learning_path_unlock_engine.dart';
import '../widgets/dialogs/track_unlock_hint_dialog.dart';
import '../widgets/track_lock_overlay.dart';

class LessonTrackLibraryScreen extends StatefulWidget {
  const LessonTrackLibraryScreen({super.key});

  @override
  State<LessonTrackLibraryScreen> createState() =>
      _LessonTrackLibraryScreenState();
}

class _LessonTrackLibraryScreenState extends State<LessonTrackLibraryScreen> {
  late Future<Map<String, dynamic>> _future;
  final Map<String, bool> _unlocked = {};
  final Map<String, String?> _reasons = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final builtIn = const LearningTrackEngine().getTracks();
    final yaml = await YamlLessonTrackLoader.instance.loadTracksFromAssets();
    final allTracks = [...builtIn, ...yaml];

    // Uses a temporary profile until real profile data becomes available.
    final profile = PlayerProfile();
    final tracks = await const TrackVisibilityFilterEngine()
        .filterUnlockedTracks(allTracks, profile);

    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('lesson_selected_track');
    final progress =
        await LessonPathProgressService.instance.computeTrackProgress();
    final unlocked = <String, bool>{};
    final reasons = <String, String?>{};
    for (final t in tracks) {
      final ok = await LearningPathUnlockEngine.instance.canUnlockTrack(t.id);
      unlocked[t.id] = ok;
      if (!ok) {
        reasons[t.id] = await TrackUnlockReasonService.instance.getUnlockReason(
          t.id,
        );
      }
    }
    _unlocked
      ..clear()
      ..addAll(unlocked);
    _reasons
      ..clear()
      ..addAll(reasons);
    return {
      'tracks': tracks,
      'selected': selected,
      'progress': progress,
      'unlocked': unlocked,
      'reasons': reasons,
    };
  }

  void _showUnlockHint(String trackId) {
    TrackUnlockHintDialog.show(context, trackId);
  }

  Future<void> _select(LessonTrack track, String? currentId) async {
    if (_unlocked[track.id] != true) {
      _showUnlockHint(track.id);
      return;
    }
    bool ok = true;
    if (currentId != null && currentId != track.id) {
      ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Сменить трек?'),
              content: const Text(
                'Вы уверены, что хотите переключить учебный путь?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('OK'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!ok) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lesson_selected_track', track.id);
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final tracks = snapshot.data?['tracks'] as List<LessonTrack>? ?? [];
        final selected = snapshot.data?['selected'] as String?;
        final progress =
            snapshot.data?['progress'] as Map<String, double>? ?? {};
        _unlocked
          ..clear()
          ..addAll(snapshot.data?['unlocked'] as Map<String, bool>? ?? {});
        _reasons
          ..clear()
          ..addAll(snapshot.data?['reasons'] as Map<String, String?>? ?? {});
        return Scaffold(
          appBar: AppBar(title: const Text('Учебные треки')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final percent = progress[track.id] ?? 0.0;
                    final steps = track.stepIds.length;
                    final isSelected = track.id == selected;
                    final card = Card(
                      color: isSelected
                          ? Colors.blueGrey[700]
                          : const Color(0xFF1E1E1E),
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
                              '${track.description}\n$steps шагов | ${percent.round()}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (_unlocked[track.id] != true &&
                                _reasons[track.id] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '🔒 ${_reasons[track.id]}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percent / 100,
                              color: Colors.orange,
                              backgroundColor: Colors.white24,
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.orange)
                            : ElevatedButton(
                                onPressed: _unlocked[track.id] == true
                                    ? () => _select(track, selected)
                                    : () => _showUnlockHint(track.id),
                                child: const Text('Выбрать'),
                              ),
                      ),
                    );
                    return TrackLockOverlay(
                      locked: _unlocked[track.id] != true,
                      reason: _reasons[track.id],
                      onTap: () => _showUnlockHint(track.id),
                      child: card,
                    );
                  },
                ),
        );
      },
    );
  }
}
