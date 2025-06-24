/// Reusable widget for displaying filtered saved hands with summary counts.
import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../theme/constants.dart';
import 'saved_hand_tile.dart';

class SavedHandListView extends StatelessWidget {
  final List<SavedHand> hands;
  final Iterable<String>? tags;
  final Iterable<String>? positions;
  final String? accuracy; // 'correct' or 'errors'
  final String title;
  final ValueChanged<SavedHand> onTap;
  final ValueChanged<SavedHand>? onFavoriteToggle;

  const SavedHandListView({
    super.key,
    required this.hands,
    required this.title,
    required this.onTap,
    this.tags,
    this.positions,
    this.accuracy,
    this.onFavoriteToggle,
  });

  bool _matchesAccuracy(SavedHand h) {
    if (accuracy == null) return true;
    final expected = h.expectedAction?.trim().toLowerCase();
    final gto = h.gtoAction?.trim().toLowerCase();
    if (expected == null || gto == null) return false;
    final equal = expected == gto;
    if (accuracy == 'correct') return equal;
    if (accuracy == 'errors') return !equal;
    return true;
  }

  List<SavedHand> _filtered() {
    return [
      for (final h in hands)
        if ((tags == null || tags!.any(h.tags.contains)) &&
            (positions == null || positions!.contains(h.heroPosition)) &&
            _matchesAccuracy(h))
          h
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, int> _summary(List<SavedHand> list) {
    var correct = 0;
    var mistakes = 0;
    for (final h in list) {
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (expected != null && gto != null) {
        if (expected == gto) {
          correct++;
        } else {
          mistakes++;
        }
      }
    }
    return {'correct': correct, 'mistakes': mistakes};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final counts = _summary(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.padding16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppConstants.fontSize20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padding16,
          ),
          child: Text(
            'Раздач: ${filtered.length} • Верно: ${counts['correct']} • Ошибки: ${counts['mistakes']}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Нет раздач',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.padding16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final hand = filtered[index];
                    return SavedHandTile(
                      hand: hand,
                      onTap: () => onTap(hand),
                      onFavoriteToggle: onFavoriteToggle == null
                          ? null
                          : () => onFavoriteToggle!(hand),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
