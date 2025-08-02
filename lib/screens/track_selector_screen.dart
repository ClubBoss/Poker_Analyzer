import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_track.dart';
import '../services/learning_track_engine.dart';
import '../services/track_lock_evaluator.dart';
import '../widgets/track_lock_overlay.dart';
import 'lesson_path_screen.dart';

class TrackSelectorScreen extends StatefulWidget {
  const TrackSelectorScreen({super.key});

  @override
  State<TrackSelectorScreen> createState() => _TrackSelectorScreenState();
}

class _TrackSelectorScreenState extends State<TrackSelectorScreen> {
  late Future<Map<String, dynamic>> _future;
  final TrackLockEvaluator _lockEvaluator = TrackLockEvaluator(
    prerequisites: const {
      'live_exploit': 'mtt_pro',
      'leak_fixer': 'live_exploit',
    },
  );

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final tracks = const LearningTrackEngine().getTracks();
    final Map<String, bool> locked = {};
    for (final t in tracks) {
      locked[t.id] = await _lockEvaluator.isLocked(t.id);
    }
    return {'tracks': tracks, 'locked': locked};
  }

  Future<void> _select(BuildContext context, LessonTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lesson_selected_track', track.id);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LessonPathScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final tracks = snapshot.data?['tracks'] as List<LessonTrack>? ?? [];
        final locked = snapshot.data?['locked'] as Map<String, bool>? ?? {};
        return Scaffold(
          appBar: AppBar(title: const Text('Выбор трека')),
          backgroundColor: const Color(0xFF121212),
          body: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isLocked = locked[track.id] == true;
              final card = Card(
                color: const Color(0xFF1E1E1E),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(track.title),
                  subtitle: Text(
                    track.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: isLocked
                      ? const Icon(Icons.lock)
                      : ElevatedButton(
                          onPressed: () => _select(context, track),
                          child: const Text('Выбрать'),
                        ),
                ),
              );
              return TrackLockOverlay(
                locked: isLocked,
                child: card,
              );
            },
          ),
        );
      },
    );
  }
}
