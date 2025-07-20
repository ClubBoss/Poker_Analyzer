import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_track.dart';
import '../models/player_profile.dart';
import '../services/learning_track_engine.dart';
import '../services/yaml_lesson_track_loader.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/track_visibility_filter_engine.dart';
import '../services/lesson_track_unlock_engine.dart';
import '../widgets/dialogs/track_unlock_hint_dialog.dart';

class LessonTrackLibraryScreen extends StatefulWidget {
  const LessonTrackLibraryScreen({super.key});

  @override
  State<LessonTrackLibraryScreen> createState() =>
      _LessonTrackLibraryScreenState();
}

class _LessonTrackLibraryScreenState extends State<LessonTrackLibraryScreen> {
  late Future<Map<String, dynamic>> _future;
  final Map<String, bool> _unlocked = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final builtIn = const LearningTrackEngine().getTracks();
    final yaml = await YamlLessonTrackLoader.instance.loadTracksFromAssets();
    final allTracks = [...builtIn, ...yaml];

    // TODO: load real profile data when available
    final profile = PlayerProfile();
    final tracks = await const TrackVisibilityFilterEngine()
        .filterUnlockedTracks(allTracks, profile);

    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('lesson_selected_track');
    final progress =
        await LessonPathProgressService.instance.computeTrackProgress();
    final unlocked = <String, bool>{};
    for (final t in tracks) {
      unlocked[t.id] = await LessonTrackUnlockEngine.instance.isUnlocked(t.id);
    }
    _unlocked
      ..clear()
      ..addAll(unlocked);
    return {
      'tracks': tracks,
      'selected': selected,
      'progress': progress,
      'unlocked': unlocked,
    };
  }

  void _showUnlockHint(String trackId) {
    showTrackUnlockHintDialog(context, trackId);
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
                    return Stack(
                      children: [
                        card,
                        if (_unlocked[track.id] != true)
                          Positioned.fill(
                            child: InkWell(
                              onTap: () => _showUnlockHint(track.id),
                              child: Container(
                                color: Colors.black54,
                                alignment: Alignment.center,
                                child: const Icon(Icons.lock,
                                    color: Colors.white, size: 40),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
