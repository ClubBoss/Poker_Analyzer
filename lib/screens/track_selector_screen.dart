import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v3/lesson_track.dart';
import '../services/learning_track_engine.dart';
import 'lesson_path_screen.dart';

class TrackSelectorScreen extends StatelessWidget {
  const TrackSelectorScreen({super.key});

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
    final tracks = const LearningTrackEngine().getTracks();
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор трека')),
      backgroundColor: const Color(0xFF121212),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(track.title),
              subtitle: Text(
                track.description,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: ElevatedButton(
                onPressed: () => _select(context, track),
                child: const Text('Выбрать'),
              ),
            ),
          );
        },
      ),
    );
  }
}
