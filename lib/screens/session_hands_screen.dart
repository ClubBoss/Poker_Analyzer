import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/saved_hand_tile.dart';
import 'hand_history_review_screen.dart';

class SessionHandsScreen extends StatelessWidget {
  final int sessionId;

  const SessionHandsScreen({super.key, required this.sessionId});

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
          : ListView.builder(
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
    );
  }
}
