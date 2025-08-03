import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/shared_prefs_helper.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../helpers/category_translations.dart';
import '../screens/training_session_screen.dart';
import '../utils/shared_prefs_keys.dart';
import 'drill_card.dart';

class CategoryDrillCard extends StatefulWidget {
  const CategoryDrillCard({super.key});

  @override
  State<CategoryDrillCard> createState() => _CategoryDrillCardState();
}

class _CategoryDrillCardState extends State<CategoryDrillCard> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.wait([
      SharedPrefsHelper.getBool(SharedPrefsKeys.topMistakeDrillDone),
      SharedPrefsHelper.getInt(SharedPrefsKeys.categoryDrillLastTime),
    ]).then((values) {
      final done = values[0] ?? false;
      final ts = values[1];
      final hide = ts != null &&
          DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(ts))
                  .inDays <
              7;
      if (mounted) setState(() => _done = done && !hide);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) return const SizedBox.shrink();
    final hands = context.watch<SavedHandManagerService>().hands;
    final map = <String, int>{};
    for (final h in hands.reversed.take(20)) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      map[cat] = (map[cat] ?? 0) + 1;
    }
    if (map.isEmpty) return const SizedBox.shrink();
    final entry = map.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (entry.value < 3) return const SizedBox.shrink();
    final name = translateCategory(entry.key).isEmpty
        ? 'Без категории'
        : translateCategory(entry.key);
    return DrillCard(
      icon: Icons.flag,
      title: 'Проработка категории',
      description: Text(name, style: const TextStyle(color: Colors.white)),
      onPressed: () async {
        final tpl = await TrainingPackService.createDrillFromCategory(
            context, entry.key);
        if (tpl == null) return;
        await context.read<TrainingSessionService>().startSession(tpl);
        await SharedPrefsHelper.setInt(
            SharedPrefsKeys.categoryDrillLastTime,
            DateTime.now().millisecondsSinceEpoch);
        if (mounted) setState(() => _done = false);
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
