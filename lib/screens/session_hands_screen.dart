import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/saved_hand_tile.dart';
import 'hand_history_review_screen.dart';

class SessionHandsScreen extends StatelessWidget {
  final int sessionId;

  const SessionHandsScreen({super.key, required this.sessionId});

  Future<void> _exportMarkdown(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final path = await manager.exportSessionHandsMarkdown(sessionId);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'session_${sessionId}.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: session_${sessionId}.md')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final path = await manager.exportSessionHandsPdf(sessionId);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'session_${sessionId}.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: session_${sessionId}.pdf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final hands = manager.hands
        .where((h) => h.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    return Scaffold(
      appBar: AppBar(
        title: Text('Сессия $sessionId'),
        centerTitle: true,
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
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: hands.length,
                    itemBuilder: (context, index) {
                      final hand = hands[index];
                      final originalIndex = manager.hands.indexOf(hand);
                      return SavedHandTile(
                        hand: hand,
                        onFavoriteToggle: () {
                          final updated =
                              hand.copyWith(isFavorite: !hand.isFavorite);
                          manager.update(originalIndex, updated);
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HandHistoryReviewScreen(hand: hand),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
