import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_pack_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_session_service.dart';
import '../services/pinned_pack_service.dart';
import '../models/saved_hand.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';
import 'pack_history_screen.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/training_pack_card.dart';
import 'empty_training_screen.dart';

class ReadyToTrainScreen extends StatefulWidget {
  const ReadyToTrainScreen({super.key});

  @override
  State<ReadyToTrainScreen> createState() => _ReadyToTrainScreenState();
}

class _ReadyToTrainScreenState extends State<ReadyToTrainScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = true;
  final Map<String, int> _progress = {};

  void _applyPinned() {
    final service = context.read<PinnedPackService>();
    for (final t in _templates) {
      t.isPinned = service.isPinned(t.id);
    }
    _templates.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return a.name.compareTo(b.name);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final builtIn = TrainingPackTemplateService.getAllTemplates(context);
    final top = await TrainingPackService.createTopMistakeDrill(context);
    final community = await TrainingPackService.createDrillFromGlobalMistakes(
      context,
    );
    SavedHand? last = context
        .read<SavedHandManagerService>()
        .hands
        .reversed
        .firstWhereOrNull((h) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      final ev = h.evLoss ?? 0.0;
      return ev.abs() >= 1.0 &&
          !h.corrected &&
          exp != null &&
          gto != null &&
          exp != gto;
    });
    final similar = last != null
        ? await TrainingPackService.createSimilarMistakeDrill(last)
        : null;
    final prefs = await SharedPreferences.getInstance();
    final list = [
      ...builtIn.where(
        (t) => !(prefs.getBool('completed_tpl_${t.id}') ?? false),
      ),
      if (top != null && !(prefs.getBool('completed_tpl_${top.id}') ?? false))
        top,
      if (community != null &&
          !(prefs.getBool('completed_tpl_${community.id}') ?? false))
        community,
      if (similar != null &&
          !(prefs.getBool('completed_tpl_${similar.id}') ?? false))
        similar,
    ];
    final prog = <String, int>{};
    for (final t in list) {
      final p = prefs.getInt('progress_tpl_${t.id}');
      if (p != null) prog[t.id] = p;
    }
    if (!mounted) return;
    if (list.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmptyTrainingScreen()),
      );
      return;
    }
    setState(() {
      _templates
        ..clear()
        ..addAll(list);
      _progress
        ..clear()
        ..addAll(prog);
      _applyPinned();
      _loading = false;
    });
  }

  Future<void> _start(TrainingPackTemplate tpl) async {
    await context.read<TrainingSessionService>().startSession(tpl);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to Train'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PackHistoryScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await TrainingPackService.generateFreshMistakeDrill(context);
          if (mounted) _load();
        },
        label: const Text('Новый Пак'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final t in _templates)
                    TrainingPackCard(
                      template: t,
                      onTap: () => _start(t),
                      progress: _progress[t.id],
                    ),
                ],
              ),
            ),
    );
  }
}
