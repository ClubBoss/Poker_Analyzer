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
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadyToTrainScreen extends StatefulWidget {
  const ReadyToTrainScreen({super.key});

  @override
  State<ReadyToTrainScreen> createState() => _ReadyToTrainScreenState();
}

class _ReadyToTrainScreenState extends State<ReadyToTrainScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = true;

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
    final community =
        await TrainingPackService.createDrillFromGlobalMistakes(context);
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
      ...builtIn.where((t) => !(prefs.getBool('completed_tpl_${t.id}') ?? false)),
      if (top != null && !(prefs.getBool('completed_tpl_${top.id}') ?? false))
        top,
      if (community != null &&
          !(prefs.getBool('completed_tpl_${community.id}') ?? false))
        community,
      if (similar != null &&
          !(prefs.getBool('completed_tpl_${similar.id}') ?? false))
        similar,
    ];
    if (!mounted) return;
    setState(() {
      _templates
        ..clear()
        ..addAll(list);
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

  Widget _card(TrainingPackTemplate t) {
    return GestureDetector(
      onLongPress: () async {
        await context.read<PinnedPackService>().toggle(t.id);
        if (mounted) setState(() {
          t.isPinned = !t.isPinned;
          _applyPinned();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (t.isPinned) const Text('📌 '),
                    Expanded(
                      child: Text(t.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (t.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t.description,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${t.spots.length} spots',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
              onPressed: () => _start(t), child: const Text('Train')),
        ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ready to Train')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final t in _templates) _card(t)],
              ),
            ),
    );
  }
}
