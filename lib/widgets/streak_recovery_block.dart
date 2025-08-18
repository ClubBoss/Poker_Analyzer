import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../models/streak_recovery_suggestion.dart';
import '../services/streak_recovery_recommender.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_session_launcher.dart';

class StreakRecoveryBlock extends StatefulWidget {
  const StreakRecoveryBlock({super.key});

  @override
  State<StreakRecoveryBlock> createState() => _StreakRecoveryBlockState();
}

class _StreakRecoveryBlockState extends State<StreakRecoveryBlock> {
  StreakRecoverySuggestion? _suggestion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final recs = await const StreakRecoveryRecommender().suggest();
    if (!mounted) return;
    setState(() {
      _suggestion = recs.firstOrNull;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final s = _suggestion;
    if (s == null) return;
    await PackLibraryLoaderService.instance.loadLibrary();
    final pack = PackLibraryLoaderService.instance.library.firstWhereOrNull(
      (p) => p.id == s.packId,
    );
    if (pack == null) return;
    await const TrainingSessionLauncher().launch(pack);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _suggestion == null) return const SizedBox.shrink();
    final s = _suggestion!;
    final accent = Theme.of(context).colorScheme.secondary;
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
            "Let's bounce back!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yesterday was a miss - try ${s.title} to rebuild momentum',
            style: const TextStyle(color: Colors.white70),
          ),
          if (s.tagFocus != null) ...[
            const SizedBox(height: 4),
            Text(
              'Focus: ${s.tagFocus}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(s.ctaText),
            ),
          ),
        ],
      ),
    );
  }
}
