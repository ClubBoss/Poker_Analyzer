import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/saved_hand.dart';
import '../models/summary_result.dart';
import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/template_storage_service.dart';
import '../services/push_fold_ev_service.dart';
import '../services/icm_push_ev_service.dart';
import '../services/session_analysis_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/pack_export_service.dart';
import '../helpers/hand_utils.dart';
import '../theme/app_colors.dart';
import '../widgets/ev_icm_chart.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../plugins/plugin_loader.dart';
import '../plugins/plugin_manager.dart';
import '../plugins/converter_registry.dart';
import '../services/service_registry.dart';
import 'v2/training_pack_play_screen.dart';
import 'session_replay_screen.dart';
import '../utils/snackbar_util.dart';

class SessionAnalysisImportScreen extends StatefulWidget {
  const SessionAnalysisImportScreen({super.key});

  @override
  State<SessionAnalysisImportScreen> createState() => _SessionAnalysisImportScreenState();
}

class _SessionAnalysisImportScreenState extends State<SessionAnalysisImportScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<SavedHand> _hands = [];
  SummaryResult? _summary;
  bool _loading = false;

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    setState(() => _controller.text = text);
    _parse();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    Uint8List? bytes = result.files.single.bytes;
    bytes ??= path != null ? await File(path).readAsBytes() : null;
    if (bytes == null) return;
    setState(() => _controller.text = String.fromCharCodes(bytes));
    _parse();
  }

  Future<void> _parse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _hands.clear();
      _summary = null;
    });
    final registry = ServiceRegistry();
    final manager = PluginManager();
    await PluginLoader().loadAll(registry, manager, context: context);
    final converters = registry.get<ConverterRegistry>();
    final plugin = converters.detectCompatible(text);
    if (plugin == null) {
      if (mounted) {
        setState(() => _loading = false);
        SnackbarUtil.showMessage(context, 'Unsupported format');
      }
      return;
    }
    final parts = text.split(RegExp(r'\n\s*\n'));
    final parsed = [
      for (final p in parts)
        if (plugin.convertFrom(p.trim()) != null) plugin.convertFrom(p.trim())!
    ];
    final service = context.read<SessionAnalysisService>();
    final result = await service.analyze(parsed);
    if (!mounted) return;
    setState(() {
      _hands
        ..clear()
        ..addAll(result.hands);
      _summary = result.summary;
      _loading = false;
    });
    final mistakes = [
      for (final h in result.hands)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h
    ];
    if (mistakes.isNotEmpty) {
      await _createPack(mistakes);
    }
  }

  double? _ev(SavedHand h) {
    final act = heroAction(h);
    if (act == null) return null;
    var ev = act.ev;
    if (ev == null && act.action.toLowerCase() == 'push') {
      final code = handCode('${h.playerCards[h.heroIndex][0].rank}${h.playerCards[h.heroIndex][0].suit} ${h.playerCards[h.heroIndex][1].rank}${h.playerCards[h.heroIndex][1].suit}');
      final stack = h.stackSizes[h.heroIndex];
      if (code != null && stack != null) {
        ev = computePushEV(heroBbStack: stack, bbCount: h.numberOfPlayers - 1, heroHand: code, anteBb: h.anteBb);
      }
    }
    return ev;
  }

  double? _icm(SavedHand h, double? ev) {
    final act = heroAction(h);
    if (act == null) return null;
    var icm = act.icmEv;
    if (icm == null && act.action.toLowerCase() == 'push') {
      final code = handCode('${h.playerCards[h.heroIndex][0].rank}${h.playerCards[h.heroIndex][0].suit} ${h.playerCards[h.heroIndex][1].rank}${h.playerCards[h.heroIndex][1].suit}');
      if (code != null && ev != null) {
        final stacks = [for (int i = 0; i < h.numberOfPlayers; i++) h.stackSizes[i] ?? 0];
        icm = computeIcmPushEV(chipStacksBb: stacks, heroIndex: h.heroIndex, heroHand: code, chipPushEv: ev);
      }
    }
    return icm;
  }

  Future<void> _createPack(List<SavedHand> mistakes) async {
    final spots = <TrainingPackSpot>[];
    for (final h in mistakes) {
      final actions = <int, List<ActionEntry>>{for (var s = 0; s < 4; s++) s: []};
      for (final a in h.actions) {
        actions[a.street] = [...(actions[a.street] ?? []), a];
      }
      final hero =
          h.playerCards.length > h.heroIndex ? h.playerCards[h.heroIndex] : <CardModel>[];
      final hc = hero.length >= 2 ? '${hero[0]} ${hero[1]}' : '';
      final handData = HandData(
        heroCards: hc,
        position: parseHeroPosition(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        board: [for (final c in h.boardCards) c.toString()],
        stacks: {for (final e in h.stackSizes.entries) '${e.key}': e.value.toDouble()},
        actions: actions,
        anteBb: h.anteBb,
      );
      spots.add(TrainingPackSpot(id: const Uuid().v4(), hand: handData));
    }
    if (spots.isEmpty) return;
    final template =
        TrainingPackTemplate(id: const Uuid().v4(), name: 'Review Imported', spots: spots);
    context.read<TemplateStorageService>().addTemplate(template);
    MistakeReviewPackService.setLatestTemplate(template);
    await context
        .read<MistakeReviewPackService>()
        .addPack([for (final s in spots) s.id], templateId: template.id);
    final start = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Review mistakes', style: TextStyle(color: Colors.white)),
        content: Text('Start ${spots.length} mistakes now?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Yes')),
        ],
      ),
    );
    if (start == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingPackPlayScreen(
            template: MistakeReviewPackService.cachedTemplate!,
            original: template,
          ),
        ),
      );
    }
  }

  Future<void> _review() async {
    final mistakes = [
      for (final h in _hands)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.toLowerCase() != h.gtoAction!.toLowerCase())
          h
    ];
    if (mistakes.isEmpty) return;
    await _createPack(mistakes);
  }

  void _replay() {
    if (_hands.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionReplayScreen(hands: _hands)),
    );
  }

  Future<bool> _confirmLargeExport(int count) async {
    if (count <= 100) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Экспортировать $count раздач?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Экспорт'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _exportCsv() async {
    if (_hands.isEmpty) return;
    if (!await _confirmLargeExport(_hands.length)) return;
    final list = [..._hands]..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final evs = <double>[];
    final icms = <double>[];
    for (final h in list) {
      final ev = _ev(h) ?? 0;
      evs.add(ev);
      icms.add(_icm(h, ev) ?? 0);
    }
    await PackExportService.exportSessionCsv(list, evs, icms);
    if (mounted) {
      SnackbarUtil.showMessage(context, 'CSV exported');
    }
  }

  Future<void> _exportPdf() async {
    if (_hands.isEmpty) return;
    if (!await _confirmLargeExport(_hands.length)) return;
    final list = [..._hands]..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final evs = <double>[];
    final icms = <double>[];
    for (final h in list) {
      final ev = _ev(h) ?? 0;
      evs.add(ev);
      icms.add(_icm(h, ev) ?? 0);
    }
    await PackExportService.exportSessionPdf(list, evs, icms);
    if (mounted) {
      SnackbarUtil.showMessage(context, 'PDF exported');
    }
  }

  Future<void> _saveHands() async {
    if (_hands.isEmpty) return;
    await context.read<SavedHandManagerService>().addHands(_hands);
    if (mounted) {
      SnackbarUtil.showMessage(context, 'Hands saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Import Analysis')),
      backgroundColor: AppColors.background,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(onPressed: _paste, label: const Text('📋 Paste')),
          const SizedBox(height: 8),
          FloatingActionButton.extended(onPressed: _pickFile, label: const Text('📂 File')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Hand history'),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _parse, child: const Text('Parse & Analyze')),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_summary != null) ...[
              Text('Hands: ${_summary!.totalHands}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Accuracy: ${_summary!.accuracy.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              EvIcmChart(hands: _hands),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _replay, child: const Text('Replay Session')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveHands, child: const Text('💾 Save to My Hands')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: _exportPdf, child: const Text('Export PDF'))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(onPressed: _exportCsv, child: const Text('Export CSV'))),
                ],
              ),
              const SizedBox(height: 16),
              if (_hands.any((h) => h.expectedAction != null && h.gtoAction != null && h.expectedAction!.toLowerCase() != h.gtoAction!.toLowerCase()))
                ElevatedButton(onPressed: _review, child: const Text('🔥 Review mistakes')),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _hands.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      itemCount: _hands.length,
                      itemBuilder: (_, i) {
                        final h = _hands[i];
                        final act = h.expectedAction ?? '';
                        final gto = h.gtoAction ?? '';
                        final ev = _ev(h);
                        final icm = _icm(h, ev);
                        final diff = ev != null && icm != null ? '${ev.toStringAsFixed(2)} / ${icm.toStringAsFixed(2)}' : '--';
                        final mistake = act.toLowerCase() != gto.toLowerCase();
                        return Card(
                          color: mistake ? AppColors.errorBg : AppColors.cardBackground,
                          child: ListTile(
                            title: Text(h.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('You: $act • GTO: $gto • $diff', style: const TextStyle(color: Colors.white70)),
                            onTap: () => showSavedHandViewerDialog(context, h),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

