import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/learning_path_booster_engine.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_session_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/training_session_screen.dart';

class BoosterPacksBlock extends StatefulWidget {
  const BoosterPacksBlock({super.key});

  @override
  State<BoosterPacksBlock> createState() => _BoosterPacksBlockState();
}

class _BoosterPacksBlockState extends State<BoosterPacksBlock> {
  bool _loading = true;
  List<TrainingPackTemplateV2> _packs = [];
  TrainingPackTemplateV2? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final mastery = context.read<TagMasteryService>();
    final packs = await const LearningPathBoosterEngine().getBoosterPacks(
      mastery: mastery,
      maxPacks: 3,
    );
    if (!mounted) return;
    setState(() {
      _packs = packs;
      _selected = packs.isNotEmpty ? packs.first : null;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final tpl = _selected;
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_packs.isEmpty) return const SizedBox.shrink();
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
            '🩹 Усиливающие паки',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _packs)
                ChoiceChip(
                  label: Text(p.name),
                  selected: _selected?.id == p.id,
                  onSelected: (_) => setState(() => _selected = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              child: const Text('🩹 Тренировать'),
            ),
          ),
        ],
      ),
    );
  }
}
