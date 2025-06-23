import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../widgets/replay_spot_widget.dart';
import '../theme/app_colors.dart';

/// Displays all spots from [pack] with option to show only mistaken ones.
class TrainingPackReviewScreen extends StatefulWidget {
  final TrainingPack pack;
  final Set<String> mistakenNames;

  const TrainingPackReviewScreen({
    super.key,
    required this.pack,
    this.mistakenNames = const {},
  });

  @override
  State<TrainingPackReviewScreen> createState() => _TrainingPackReviewScreenState();
}

class _TrainingPackReviewScreenState extends State<TrainingPackReviewScreen> {
  bool _onlyMistakes = false;

  List<SavedHand> get _visibleHands {
    if (!_onlyMistakes) return widget.pack.hands;
    return [
      for (final h in widget.pack.hands)
        if (widget.mistakenNames.contains(h.name)) h
    ];
  }

  Widget _buildHandTile(SavedHand hand) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(hand.name, style: const TextStyle(color: Colors.white)),
        subtitle: Wrap(
          spacing: 4,
          children: [for (final t in hand.tags) Chip(label: Text(t))],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 5; i++)
              Icon(
                i < hand.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) =>
                ReplaySpotWidget(spot: TrainingSpot.fromSavedHand(hand)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hands = _visibleHands;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.name),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Show mistakes only'),
            value: _onlyMistakes,
            onChanged: widget.mistakenNames.isEmpty
                ? null
                : (v) => setState(() => _onlyMistakes = v),
            activeColor: Colors.orange,
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: hands.isEmpty
                ? const Center(
                    child: Text(
                      'No spots',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: hands.length,
                    itemBuilder: (context, index) => _buildHandTile(hands[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

