import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/session_label_overlay.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_export_service.dart';
import '../services/saved_hand_stats_service.dart';
import '../services/session_note_service.dart';
import '../services/session_manager.dart';
import '../widgets/saved_hand_tile.dart';
import '../helpers/date_utils.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../widgets/sync_status_widget.dart';

class SessionHandsScreen extends StatefulWidget {
  final int sessionId;

  const SessionHandsScreen({super.key, required this.sessionId});

  @override
  State<SessionHandsScreen> createState() => _SessionHandsScreenState();
}

class _SessionHandsScreenState extends State<SessionHandsScreen> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final noteService = context.read<SessionNoteService>();
    _noteController =
        TextEditingController(text: noteService.noteFor(widget.sessionId));
    _noteController.addListener(
        () => noteService.setNote(widget.sessionId, _noteController.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showSessionLabelOverlay(context, 'Сессия ${widget.sessionId}');
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _actionType(SavedHand hand) {
    final expected = hand.expectedAction?.trim().toLowerCase();
    final gto = hand.gtoAction?.trim().toLowerCase();
    if (expected != null && gto != null && expected != gto) {
      return 'Error';
    }
    if (expected == null || expected.isEmpty) return 'Other';
    if (expected.contains('push')) return 'Push';
    if (expected.contains('call')) return 'Call';
    if (expected.contains('fold')) return 'Fold';
    return 'Other';
  }

  PageRouteBuilder _buildSwipeRoute(int targetId, {required bool fromRight}) {
    final begin = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => SessionHandsScreen(sessionId: targetId),
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut))
            .animate(animation);
        return SlideTransition(position: offset, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildSummary(List<SavedHand> hands) {
    final start = hands.last.savedAt;
    final end = hands.first.savedAt;
    final duration = end.difference(start);
    int correct = 0;
    int incorrect = 0;
    for (final h in hands) {
      final expected = h.expectedAction;
      final gto = h.gtoAction;
      if (expected != null && gto != null) {
        if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }

    final totalDecisions = correct + incorrect;
    final winrate = totalDecisions > 0
        ? (correct / totalDecisions * 100).toStringAsFixed(1)
        : null;
    final ev = correct - incorrect;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padding16, vertical: 8),
      child: Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Раздач: ${hands.length}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Начало: ${formatDateTime(start)}',
                  style: const TextStyle(color: Colors.white)),
              Text('Конец: ${formatDateTime(end)}',
                  style: const TextStyle(color: Colors.white)),
              Text('Длительность: ${formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Верно: $correct • Ошибки: $incorrect',
                  style: const TextStyle(color: Colors.white)),
              if (winrate != null) ...[
                const SizedBox(height: 4),
                Text('Winrate: $winrate% • EV: ${ev >= 0 ? '+' : ''}$ev',
                    style: const TextStyle(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padding16, vertical: 8),
      child: Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Заметка о сессии',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SyncStatusIcon.of(context),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final exporter = context.read<SavedHandExportService>();
    final note = context.read<SessionNoteService>().noteFor(widget.sessionId);
    final path =
        await exporter.exportSessionHandsMarkdown(widget.sessionId, note: note);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)],
        text: 'session_${widget.sessionId}.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Файл сохранён: session_${widget.sessionId}.md')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final exporter = context.read<SavedHandExportService>();
    final note = context.read<SessionNoteService>().noteFor(widget.sessionId);
    final path =
        await exporter.exportSessionHandsPdf(widget.sessionId, note: note);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)],
        text: 'session_${widget.sessionId}.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Файл сохранён: session_${widget.sessionId}.pdf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final stats = context.watch<SavedHandStatsService>();
    final hands = manager.hands
        .where((h) => h.sessionId == widget.sessionId)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    final sessionIds = stats.handsBySession().keys.toList()..sort();
    final currentIndex = sessionIds.indexOf(widget.sessionId);
    final previousId = currentIndex > 0 ? sessionIds[currentIndex - 1] : null;
    final nextId = currentIndex < sessionIds.length - 1
        ? sessionIds[currentIndex + 1]
        : null;

    Widget buildGroupedList() {
      final groups = <String, List<SavedHand>>{
        'Push': [],
        'Call': [],
        'Fold': [],
        'Error': [],
        'Other': [],
      };
      for (final h in hands) {
        groups[_actionType(h)]!.add(h);
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in groups.entries)
            if (entry.value.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final hand in entry.value)
                SavedHandTile(
                  hand: hand,
                  onFavoriteToggle: () {
                    final originalIndex = manager.hands.indexOf(hand);
                    final updated = hand.copyWith(isFavorite: !hand.isFavorite);
                    manager.update(originalIndex, updated);
                  },
                  onTap: () {
                    showSavedHandViewerDialog(context, hand);
                  },
                ),
            ]
        ],
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300 && nextId != null) {
          Navigator.pushReplacement(
            context,
            _buildSwipeRoute(nextId, fromRight: true),
          );
        } else if (velocity > 300 && previousId != null) {
          Navigator.pushReplacement(
            context,
            _buildSwipeRoute(previousId, fromRight: false),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Сессия ${widget.sessionId}'),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context)],
        ),
        body: hands.isEmpty
            ? const Center(
                child: Text(
                  'Нет раздач в этой сессии',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _exportMarkdown(context),
                            child: const Text('Экспорт в Markdown'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _exportPdf(context),
                            child: const Text('Экспорт в PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await context
                                  .read<SessionManager>()
                                  .reset(widget.sessionId);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text('Reset Session'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSummary(hands),
                  _buildNoteField(),
                  Expanded(child: buildGroupedList()),
                ],
              ),
      ),
    );
  }
}
