import 'package:flutter/material.dart';

import '../repositories/learning_path_repository.dart';
import '../models/learning_path_track_model.dart';
import '../models/learning_path_template_v2.dart';
import '../widgets/track_section_widget.dart';

/// Displays all available learning path tracks and their paths.
class LearningPathLibraryScreen extends StatefulWidget {
  const LearningPathLibraryScreen({super.key});

  @override
  State<LearningPathLibraryScreen> createState() => _LearningPathLibraryScreenState();
}

class _LearningPathLibraryScreenState extends State<LearningPathLibraryScreen> {
  late Future<Map<LearningPathTrackModel, List<LearningPathTemplateV2>>> _future;
  final _repo = LearningPathRepository();

  @override
  void initState() {
    super.initState();
    _future = _repo.loadAllTracksWithPaths();
  }

  Future<void> _reload() async {
    setState(() => _future = _repo.loadAllTracksWithPaths());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<LearningPathTrackModel, List<LearningPathTemplateV2>>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        return Scaffold(
          appBar: AppBar(title: const Text('📚 Обучающие треки')),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
                  ? const Center(child: Text('Нет доступных треков'))
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          for (final entry in data.entries)
                            TrackSectionWidget(
                              track: entry.key,
                              paths: entry.value,
                            ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
