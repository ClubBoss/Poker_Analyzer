import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../services/theory_track_resume_service.dart';
import '../services/theory_track_library_service.dart';
import '../screens/learning_track_screen.dart';
import '../models/theory_track_model.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key});

  Future<_ResumeData?> _load() async {
    final trackId =
        await TheoryTrackResumeService.instance.getLastVisitedTrackId();
    if (trackId == null) return null;
    final blockId = await TheoryTrackResumeService.instance.getLastVisitedBlock(
      trackId,
    );
    if (blockId == null) return null;
    await TheoryTrackLibraryService.instance.loadAll();
    final track = TheoryTrackLibraryService.instance.getById(trackId);
    if (track == null) return null;
    return _ResumeData(track, blockId);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_ResumeData?>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final block = data.track.blocks.firstWhereOrNull(
          (b) => b.id == data.blockId,
        );
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
                '📚 Continue learning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                data.track.title,
                style: const TextStyle(color: Colors.white),
              ),
              if (block != null)
                Text(
                  block.title,
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LearningTrackScreen(
                          track: data.track,
                          initialBlockId: data.blockId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResumeData {
  final TheoryTrackModel track;
  final String blockId;
  const _ResumeData(this.track, this.blockId);
}
