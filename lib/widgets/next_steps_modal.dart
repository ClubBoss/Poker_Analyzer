import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_path_template_v2.dart';
import '../models/v2/training_pack_template.dart';
import '../services/learning_path_registry_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/training_session_service.dart';
import '../screens/learning_path_screen_v2.dart';
import '../screens/training_session_screen.dart';

class NextStepsModal extends StatefulWidget {
  final String completedPathId;
  const NextStepsModal({super.key, required this.completedPathId});

  static Future<void> show(BuildContext context, String completedPathId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => NextStepsModal(completedPathId: completedPathId),
    );
  }

  @override
  State<NextStepsModal> createState() => _NextStepsModalState();
}

class _NextStepsData {
  final List<LearningPathTemplateV2> paths;
  final TrainingPackTemplate? booster;
  _NextStepsData({required this.paths, this.booster});
}

class _NextStepsModalState extends State<NextStepsModal> {
  late Future<_NextStepsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NextStepsData> _load() async {
    final registry = LearningPathRegistryService.instance;
    final templates = await registry.loadAll();
    final unlocked = <LearningPathTemplateV2>[
      for (final t in templates)
        if (t.prerequisitePathIds.contains(widget.completedPathId)) t,
    ];
    final paths = unlocked.take(2).toList();

    TrainingPackTemplate? booster;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('showWeaknessOverlay') ?? true) {
      final mastery = context.read<TagMasteryService>();
      final weak = await mastery.findWeakTags(threshold: 0.6);
      if (weak.isNotEmpty) {
        final service = context.read<WeakSpotRecommendationService>();
        final pack = await service.buildPack();
        if (pack != null && pack.spots.length >= 5) {
          booster = pack;
        }
      }
    }

    return _NextStepsData(paths: paths, booster: booster);
  }

  void _openPath(LearningPathTemplateV2 path) {
    Navigator.pop(context); // close dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LearningPathScreen(template: path, highlightedStageId: null),
      ),
    );
  }

  Future<void> _startBooster(TrainingPackTemplate pack) async {
    Navigator.pop(context);
    await context.read<TrainingSessionService>().startSession(
      pack,
      persist: false,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  void _skip() {
    Navigator.pop(context);
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return AlertDialog(
      title: const Text('Что дальше?'),
      content: FutureBuilder<_NextStepsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final data =
              snapshot.data ?? _NextStepsData(paths: const [], booster: null);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in data.paths)
                  ListTile(
                    title: Text(p.title),
                    trailing: ElevatedButton(
                      onPressed: () => _openPath(p),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Начать'),
                    ),
                    onTap: () => _openPath(p),
                  ),
                if (data.booster != null)
                  ListTile(
                    title: const Text('Усилить слабую зону?'),
                    subtitle: Text('${data.booster!.spotCount} раздач'),
                    trailing: ElevatedButton(
                      onPressed: () => _startBooster(data.booster!),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Начать'),
                    ),
                    onTap: () => _startBooster(data.booster!),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [TextButton(onPressed: _skip, child: const Text('Позже'))],
    );
  }
}
