import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../widgets/saved_hand_list_view.dart';
import 'hand_history_review_screen.dart';

/// Screen showing mistakes grouped by tag.
///
/// The list is populated using [EvaluationExecutorService.summarizeHands]
/// so that each tag displays how many errors were made. Tapping a tag
/// navigates to a filtered [SavedHandListView] with only the mistakes for
/// that tag.
class TagMistakeOverviewScreen extends StatelessWidget {
  const TagMistakeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final summary = EvaluationExecutorService().summarizeHands(hands);
    final entries = summary.mistakeTagFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки по тегам'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in entries)
            ListTile(
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              trailing:
                  Text(e.value.toString(), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _TagMistakeHandsScreen(tag: e.key),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TagMistakeHandsScreen extends StatelessWidget {
  final String tag;
  const _TagMistakeHandsScreen({required this.tag});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: hands,
        tags: [tag],
        accuracy: 'errors',
        title: 'Ошибки: $tag',
        onTap: (hand) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandHistoryReviewScreen(hand: hand),
            ),
          );
        },
      ),
    );
  }
}
