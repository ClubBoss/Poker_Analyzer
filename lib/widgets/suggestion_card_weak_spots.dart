import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/training/engine/training_type_engine.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/training_session_service.dart';
import '../services/pack_generator_service.dart';
import '../services/user_action_logger.dart';
import '../screens/training_session_screen.dart';

class SuggestionCardWeakSpots extends StatefulWidget {
  const SuggestionCardWeakSpots({super.key});

  @override
  State<SuggestionCardWeakSpots> createState() =>
      _SuggestionCardWeakSpotsState();
}

class _SuggestionCardWeakSpotsState extends State<SuggestionCardWeakSpots> {
  bool _loading = true;
  TrainingType? _type;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final service = context.read<WeakSpotRecommendationService>();
    final result = await service.detectWeakTrainingType();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _type = TrainingType.values.firstWhere(
        (e) => e.name == result,
        orElse: () => null,
      );
    });
    if (_type != null) {
      await UserActionLogger.instance.log(
        'weak_spot_suggestion_open:${_type!.name}',
      );
    }
  }

  Future<void> _start() async {
    final t = _type;
    if (t == null) return;
    await UserActionLogger.instance.log('weak_spot_suggestion_start:${t.name}');
    TrainingPackTemplate? tpl;
    if (t == TrainingType.pushFold) {
      tpl = await PackGeneratorService.generatePushFoldPack(
        id: 'weak_type_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Push/Fold Focus',
        heroBbStack: 10,
        playerStacksBb: const [10, 10],
        heroPos: HeroPosition.sb,
        heroRange: PackGeneratorService.topNHands(25).toList(),
      );
    }
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _type == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Ваша слабая зона',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(_type!.icon, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Рекомендуем потренировать: ${_type!.label}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              child: const Text('🔁 Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
