import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../services/training_pack_library_loader_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/booster_progress_tracker_service.dart';
import '../services/training_session_launcher.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Dashboard tile showing a personalized booster recommendation.
class RecommendedDrillTile extends StatefulWidget {
  const RecommendedDrillTile({super.key});

  @override
  State<RecommendedDrillTile> createState() => _RecommendedDrillTileState();
}

class _RecommendedDrillTileState extends State<RecommendedDrillTile> {
  TrainingPackTemplateV2? _pack;
  double? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final mastery = context.read<TagMasteryService>();
    final attempts = await mastery.computeAttempts();
    final masteryMap = await mastery.computeMastery();
    final sorted = masteryMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    String? tag;
    for (final e in sorted) {
      final count = attempts[e.key] ?? 0;
      if (count >= 5) {
        tag = e.key;
        break;
      }
    }
    if (tag == null) {
      setState(() => _loading = false);
      return;
    }
    await TrainingPackLibraryLoaderService.instance.preloadLibrary();
    final packs = TrainingPackLibraryLoaderService.instance.loadedTemplates;
    final pack = packs.firstWhereOrNull((p) =>
        p.meta['type'] == 'booster' &&
        p.meta['tag']?.toString().toLowerCase() == tag);
    double? progress;
    if (pack != null) {
      final idx =
          await BoosterProgressTrackerService.instance.getLastIndex(pack.id);
      if (idx != null && pack.spotCount > 0) {
        progress = (idx + 1) / pack.spotCount;
      }
    }
    if (!mounted) return;
    setState(() {
      _pack = pack;
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final pack = _pack;
    if (pack == null) return;
    final tracker = BoosterProgressTrackerService.instance;
    final idx = await tracker.getLastIndex(pack.id);
    final completed = await tracker.isCompleted(pack.id);
    var start = 0;
    if (!completed && idx != null && idx > 0 && idx < pack.spotCount) {
      final resume = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resume?'),
          content: Text('Continue from spot ${idx + 1}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Restart')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (resume == null || resume) {
        start = idx;
      } else {
        await tracker.clearProgress(pack.id);
      }
    }
    await const TrainingSessionLauncher().launch(pack, startIndex: start);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final pack = _pack!;
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
            'Recommended Next Drill',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(pack.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (pack.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(pack.description,
                  style: const TextStyle(color: Colors.white70)),
            ),
          if (_progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress!.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Train Now'),
            ),
          ),
        ],
      ),
    );
  }
}
