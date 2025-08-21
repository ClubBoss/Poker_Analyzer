import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/v2/training_pack_template.dart';
import '../services/training_gap_notification_service.dart';
import '../services/training_gap_detector_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_type_stats_service.dart';
import '../services/weak_training_type_detector.dart';
import '../services/training_session_service.dart';
import '../helpers/category_translations.dart';
import '../core/training/engine/training_type_engine.dart';
import '../screens/training_session_screen.dart';

class SuggestedPackTile extends StatefulWidget {
  final String? excludeId;
  const SuggestedPackTile({super.key, this.excludeId});

  @override
  State<SuggestedPackTile> createState() => _SuggestedPackTileState();
}

class _SuggestedPackTileState extends State<SuggestedPackTile> {
  TrainingPackTemplate? _pack;
  String? _reason;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tpl = await const TrainingGapNotificationService().suggestNextPack(
      excludeId: widget.excludeId,
    );
    if (tpl == null) return;
    String? reason;
    final weakCategory =
        await const TrainingGapDetectorService().detectWeakCategory();
    if (weakCategory != null && tpl.category == weakCategory) {
      reason = 'Слабая категория: ${translateCategory(weakCategory)}';
    } else {
      await PackLibraryLoaderService.instance.loadLibrary();
      final packs = [
        for (final t in PackLibraryLoaderService.instance.library)
          TrainingPackTemplate.fromJson(t.toJson()),
      ];
      final stats = await const TrainingTypeStatsService()
          .calculateCompletionPercent(packs);
      final weakType = const WeakTrainingTypeDetector().findWeakestType(stats);
      if (weakType != null && tpl.trainingType == weakType) {
        reason = 'Слабый тип: ${weakType.label}';
      }
    }
    if (mounted) {
      setState(() {
        _pack = tpl;
        _reason = reason;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final l = AppLocalizations.of(context)!;
    final pack = _pack!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 Рекомендуем для прогресса',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(pack.name, style: const TextStyle(color: Colors.white)),
          if (_reason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _reason!,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                await context.read<TrainingSessionService>().startSession(pack);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrainingSessionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(l.startTraining),
            ),
          ),
        ],
      ),
    );
  }
}
