import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/import_export/training_generator.dart';
import 'package:poker_analyzer/widgets/replay_spot_widget.dart';
import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../helpers/training_pack_storage.dart';
import '../services/goals_service.dart';
import '../helpers/date_utils.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/booster_recap_hook.dart';
import '../helpers/mistake_advice.dart';
import '../widgets/sync_status_widget.dart';
import 'saved_hand_editor_screen.dart';

/// Displays a saved hand with simple playback controls.
/// Shows GTO recommendation and range group when available.
class HandHistoryReviewScreen extends StatefulWidget {
  final SavedHand hand;

  const HandHistoryReviewScreen({super.key, required this.hand});

  @override
  State<HandHistoryReviewScreen> createState() =>
      _HandHistoryReviewScreenState();
}

class _HandHistoryReviewScreenState extends State<HandHistoryReviewScreen> {
  String? _selectedAction;
  late TextEditingController _commentController;
  late SavedHand _hand;

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Markdown'),
              onTap: () {
                Navigator.pop(context);
                _exportMarkdown();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _hand = widget.hand;
    _commentController = TextEditingController(text: _hand.comment ?? '');
    final service = Provider.of<GoalsService>(context, listen: false);
    final goal = service.dailyGoal;
    final action = _hand.expectedAction?.trim().toLowerCase();
    final gto = _hand.gtoAction?.trim().toLowerCase();
    final isMistake = action != null && gto != null && action != gto;
    final dailyMistake =
        goal != null && service.dailyGoalIndex == 0 && isMistake;
    if (dailyMistake) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        service.recordMistakeReviewed(context);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      service.updateMistakeReviewStreak(isMistake, context: context);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BoosterRecapHook.instance.onReviewOpened(
        handId: _hand.spotId ?? _hand.name,
        tags: _hand.tags,
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveComment(String text) async {
    final manager = context.read<SavedHandManagerService>();
    final index = manager.hands.indexOf(_hand);
    if (index >= 0) {
      final updated = _hand.copyWith(
        comment: text.trim().isNotEmpty ? text.trim() : null,
      );
      await manager.update(index, updated);
      _hand = updated;
    }
  }

  Future<void> _exportMarkdown() async {
    final hand = _hand;
    final heroCards = hand.playerCards[hand.heroIndex].join(' ');
    final board = hand.boardCards.map((c) => c.toString()).join(' ');
    final stack = hand.stackSizes[hand.heroIndex] ?? 0;
    final buffer = StringBuffer()
      ..writeln('## ${hand.name}')
      ..writeln('- Позиция: ${hand.heroPosition}')
      ..writeln('- Стек: $stack')
      ..writeln('- Карты: $heroCards');
    if (board.isNotEmpty) buffer.writeln('- Борд: $board');
    if (_selectedAction != null) {
      buffer.writeln('- Действие: $_selectedAction');
    }
    if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
      buffer.writeln('- GTO: ${hand.gtoAction}');
    }
    if (hand.tags.isNotEmpty) {
      buffer.writeln('- Теги: ${hand.tags.join(', ')}');
    }
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      buffer.writeln('- Комментарий: $comment');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hand_export.md');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'hand_export.md');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: hand_export.md')),
      );
    }
  }

  Future<void> _exportPdf() async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final hand = _hand;
    final heroCards = hand.playerCards[hand.heroIndex].join(' ');
    final board = hand.boardCards.map((c) => c.toString()).join(' ');
    final stack = hand.stackSizes[hand.heroIndex] ?? 0;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(hand.name,
                  style: pw.TextStyle(font: boldFont, fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Text('Позиция: ${hand.heroPosition}',
                  style: pw.TextStyle(font: regularFont)),
              pw.Text('Стек: $stack', style: pw.TextStyle(font: regularFont)),
              pw.Text('Карты: $heroCards',
                  style: pw.TextStyle(font: regularFont)),
              if (board.isNotEmpty)
                pw.Text('Борд: $board', style: pw.TextStyle(font: regularFont)),
              if (_selectedAction != null)
                pw.Text('Действие: $_selectedAction',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty)
                pw.Text('GTO: ${hand.gtoAction}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.tags.isNotEmpty)
                pw.Text('Теги: ${hand.tags.join(', ')}',
                    style: pw.TextStyle(font: regularFont)),
              if (_commentController.text.trim().isNotEmpty)
                pw.Text('Комментарий: ${_commentController.text.trim()}',
                    style: pw.TextStyle(font: regularFont)),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hand_export.pdf');
    await file.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: hand_export.pdf')),
      );
    }
  }

  String? _playerAction() => _selectedAction ?? _hand.expectedAction;

  String? _deriveAdvice() {
    for (final t in _hand.tags) {
      if (kMistakeAdvice.containsKey(t)) return kMistakeAdvice[t];
    }
    if (kMistakeAdvice.containsKey(_hand.heroPosition)) {
      return kMistakeAdvice[_hand.heroPosition];
    }
    return null;
  }

  Widget _buildMistakeCard(String message, {String? advice}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(color: Colors.white)),
                if (advice != null) ...[
                  const SizedBox(height: 4),
                  Text(advice,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _spotFromHand(SavedHand hand) {
    final heroCards = hand.playerCards[hand.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[
      for (final a in hand.actions)
        if (a.street == 0) a
    ];
    final stacks = <String, double>{
      for (int i = 0; i < hand.numberOfPlayers; i++)
        '$i': (hand.stackSizes[i] ?? 0).toDouble()
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(hand.heroPosition),
        heroIndex: hand.heroIndex,
        playerCount: hand.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
      ),
    );
  }

  Future<void> _addToPack() async {
    final templates = await TrainingPackStorage.load();
    if (templates.isEmpty) return;
    final selected = await showDialog<TrainingPackTemplate>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Add to Pack'),
        children: [
          for (final t in templates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text(t.name),
            ),
        ],
      ),
    );
    if (selected == null) return;
    final spot = _spotFromHand(_hand);
    selected.spots.add(spot);
    await TrainingPackStorage.save(templates);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Spot added')));
    }
  }

  Widget _buildGoalProgress(BuildContext context) {
    final service = context.watch<GoalsService>();
    final goal = service.dailyGoal;
    if (goal == null || service.dailyGoalIndex != 0) {
      return const SizedBox.shrink();
    }
    final accent = Theme.of(context).colorScheme.secondary;
    final value = (goal.progress / goal.target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 300),
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${goal.progress}/${goal.target}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spot = TrainingGenerator().generateFromSavedHand(_hand);
    final gto = _hand.gtoAction;
    final group = _hand.rangeGroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_hand.name} \u2022 ${formatLongDate(_hand.savedAt)}',
        ),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push<SavedHand>(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedHandEditorScreen(hand: _hand),
                ),
              );
              if (result != null && mounted) {
                final manager = context.read<SavedHandManagerService>();
                final idx = manager.hands.indexOf(_hand);
                if (idx >= 0) await manager.update(idx, result);
                setState(() => _hand = result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalProgress(context),
            if (_playerAction() != null &&
                gto != null &&
                _playerAction()!.trim().toLowerCase() !=
                    gto.trim().toLowerCase()) ...[
              _buildMistakeCard(
                _hand.feedbackText ?? 'Ваше действие отличается от GTO',
                advice: _deriveAdvice(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Text('Позиция:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_hand.heroPosition),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  labelStyle: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReplaySpotWidget(
              spot: spot,
              expectedAction: _hand.expectedAction,
              gtoAction: _hand.gtoAction,
              evLoss: _hand.evLoss,
              feedbackText: _hand.feedbackText,
            ),
            const SizedBox(height: 12),
            if ((gto != null && gto.isNotEmpty) ||
                (group != null && group.isNotEmpty))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (gto != null && gto.isNotEmpty)
                    Text('Рекомендовано: $gto',
                        style: const TextStyle(color: Colors.white)),
                  if (group != null && group.isNotEmpty)
                    Text('Группа: $group',
                        style: const TextStyle(color: Colors.white)),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              onChanged: _saveComment,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Комментарий',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _exportMarkdown,
                  child: const Text('Экспорт Markdown'),
                ),
                ElevatedButton(
                  onPressed: _exportPdf,
                  child: const Text('Экспорт PDF'),
                ),
                ElevatedButton(
                  onPressed: _addToPack,
                  child: const Text('➕ Add to Pack'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton('Push'),
                _actionButton('Fold'),
                _actionButton('Call'),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedAction != null)
              Text(
                'Вы выбрали: $_selectedAction. GTO рекомендует: ${gto ?? '-'}',
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label) {
    final bool isSelected = _selectedAction == label;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedAction = label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueGrey : Colors.black87,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
