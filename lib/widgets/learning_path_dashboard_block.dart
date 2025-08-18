import 'package:flutter/material.dart';
import '../repositories/learning_path_repository.dart';
import '../services/learning_path_progress_engine.dart';
import '../services/session_log_service.dart';
import '../services/training_session_service.dart';
import '../models/learning_path_track_model.dart';
import '../models/learning_path_template_v2.dart';
import '../screens/path_library_screen.dart';

/// Dashboard widget highlighting the next learning path to continue.
class LearningPathDashboardBlock extends StatefulWidget {
  const LearningPathDashboardBlock({super.key});

  @override
  State<LearningPathDashboardBlock> createState() =>
      _LearningPathDashboardBlockState();
}

class _LearningPathDashboardBlockState
    extends State<LearningPathDashboardBlock> {
  late Future<_BlockData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BlockData?> _load() async {
    final repo = LearningPathRepository();
    final engine = LearningPathProgressEngine(
      logs: SessionLogService(sessions: TrainingSessionService()),
    );
    final data = await repo.loadAllTracksWithPaths();
    if (data.isEmpty) return null;
    final tracks = data.keys.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final track in tracks) {
      final paths = data[track] ?? const <LearningPathTemplateV2>[];
      final progress = <LearningPathTemplateV2, double>{};
      for (final p in paths) {
        progress[p] = await engine.getPathProgress(p.id);
      }
      final incomplete = progress.entries.where((e) => e.value < 1.0).toList();
      if (incomplete.isEmpty) continue;
      incomplete.sort((a, b) => a.value.compareTo(b.value));
      final best = incomplete.first;
      return _BlockData(track: track, path: best.key, progress: best.value);
    }
    return null;
  }

  void _openPath() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PathLibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_BlockData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final pct = (data.progress.clamp(0.0, 1.0) * 100).round();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.track.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.path.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (data.path.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data.path.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('$pct%', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _openPath,
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Продолжить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlockData {
  final LearningPathTrackModel track;
  final LearningPathTemplateV2 path;
  final double progress;
  const _BlockData({
    required this.track,
    required this.path,
    required this.progress,
  });
}
