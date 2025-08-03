import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
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
  bool _showCompleted = false;
  final Map<String, bool> _completed = {};

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
    PreferencesService.getInstance().then((p) {
      _showCompleted = p.getBool('show_completed_packs') ?? false;
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final builtIn = TrainingPackTemplateService.getAllTemplates(context);
    final top = await TrainingPackService.createTopMistakeDrill(context);
    final community = await TrainingPackService.createDrillFromGlobalMistakes(
      context,
    );
    final SavedHand? last = context
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
    final prefs = await PreferencesService.getInstance();
    final list = [
      ...builtIn.where(
        (t) =>
            _showCompleted ||
            !(prefs.getBool('completed_tpl_${t.id}') ?? false),
      ),
      if (top != null &&
          (_showCompleted ||
              !(prefs.getBool('completed_tpl_${top.id}') ?? false)))
        top,
      if (community != null &&
          (_showCompleted ||
              !(prefs.getBool('completed_tpl_${community.id}') ?? false)))
        community,
      if (similar != null &&
          (_showCompleted ||
              !(prefs.getBool('completed_tpl_${similar.id}') ?? false)))
        similar,
    ];
    final prog = <String, int>{};
    final done = <String, bool>{};
    for (final t in list) {
      final p = prefs.getInt('progress_tpl_${t.id}');
      if (p != null) prog[t.id] = p;
      done[t.id] = prefs.getBool('completed_tpl_${t.id}') ?? false;
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
      _completed
        ..clear()
        ..addAll(done);
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
      if (mounted) _load();
    }
  }

  Future<void> _toggle(bool value) async {
    final p = await PreferencesService.getInstance();
    await p.setBool('show_completed_packs', value);
    setState(() => _showCompleted = value);
    _load();
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
          PopupMenuButton<bool>(
            onSelected: _toggle,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: !_showCompleted,
                checked: _showCompleted,
                child: const Text('Показать завершённые'),
              ),
            ],
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
              child: Builder(builder: (context) {
                final completedList = [
                  for (final t in _templates)
                    if (_completed[t.id] ?? false) t
                ];
                final todoList = [
                  for (final t in _templates)
                    if (!(_completed[t.id] ?? false)) t
                ];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final t in todoList)
                      TrainingPackCard(
                        template: t,
                        onTap: () => _start(t),
                        progress: _progress[t.id],
                        onRefresh: _load,
                      ),
                    if (_showCompleted && completedList.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                        child: Text('Завершённые',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      for (final t in completedList)
                        TrainingPackCard(
                          template: t,
                          onTap: () => _start(t),
                          progress: _progress[t.id],
                          onRefresh: _load,
                          dimmed: true,
                        ),
                    ],
                  ],
                );
              }),
            ),
    );
  }
}
