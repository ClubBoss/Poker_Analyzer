import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/shared_prefs_helper.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';
import '../utils/shared_prefs_keys.dart';
import 'drill_card.dart';

class TopMistakeDrillCard extends StatefulWidget {
  const TopMistakeDrillCard({super.key});

  @override
  State<TopMistakeDrillCard> createState() => _TopMistakeDrillCardState();
}

class _TopMistakeDrillCardState extends State<TopMistakeDrillCard> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    SharedPrefsHelper.getBool(SharedPrefsKeys.topMistakeDrillDone).then((v) {
      if (mounted) setState(() => _done = v ?? false);
    });
  }

  Future<void> _mark() async {
    await SharedPrefsHelper.setBool(
        SharedPrefsKeys.topMistakeDrillDone, true);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final map = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      map[cat] = (map[cat] ?? 0) + (h.evLoss ?? 0);
    }
    if (_done || map.length < 3) return const SizedBox.shrink();
    return DrillCard(
      icon: Icons.bolt,
      title: 'Топ ошибки',
      description:
          const Text('Восстановите EV', style: TextStyle(color: Colors.white70)),
      buttonText: 'Начать',
      onPressed: () async {
        final tpl = await TrainingPackService.createTopMistakeDrill(context);
        if (tpl == null) return;
        await context.read<TrainingSessionService>().startSession(tpl);
        await _mark();
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TrainingSessionScreen()),
          );
        }
      },
    );
  }
}
