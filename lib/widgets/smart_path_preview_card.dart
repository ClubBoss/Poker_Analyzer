import 'package:flutter/material.dart';

import '../screens/path_overview_screen.dart';
import '../models/path_difficulty.dart';

/// Visual card widget showing a brief overview of a learning path.
class SmartPathPreviewCard extends StatelessWidget {
  final String pathId;
  final String pathTitle;
  final String pathDescription;
  final int stageCount;
  final int packCount;
  final String? coverAsset;
  final PathDifficulty difficulty;

  const SmartPathPreviewCard({
    super.key,
    required this.pathId,
    required this.pathTitle,
    required this.pathDescription,
    required this.stageCount,
    required this.packCount,
    this.coverAsset,
    this.difficulty = PathDifficulty.easy,
  });

  IconData _difficultyIcon() {
    switch (difficulty) {
      case PathDifficulty.easy:
        return Icons.sentiment_satisfied_alt;
      case PathDifficulty.medium:
        return Icons.sentiment_neutral;
      case PathDifficulty.hard:
        return Icons.sentiment_dissatisfied;
    }
  }

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PathOverviewScreen(pathId: pathId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF242428),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverAsset != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Image.asset(
                  coverAsset!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 100,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white54,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pathTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (pathDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        pathDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$stageCount стадий · $packCount паков',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(_difficultyIcon(), color: accent, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
