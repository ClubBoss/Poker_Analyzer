import 'package:flutter/material.dart';
import 'package:poker_ai_analyzer/models/saved_hand.dart';
import 'package:poker_ai_analyzer/import_export/training_generator.dart';
import 'package:poker_ai_analyzer/widgets/replay_spot_widget.dart';

/// Displays a saved hand with simple playback controls.
/// Shows GTO recommendation and range group when available.
class HandHistoryReviewScreen extends StatefulWidget {
  final SavedHand hand;

  const HandHistoryReviewScreen({super.key, required this.hand});

  @override
  State<HandHistoryReviewScreen> createState() => _HandHistoryReviewScreenState();
}

class _HandHistoryReviewScreenState extends State<HandHistoryReviewScreen> {
  String? _selectedAction;

  @override
  Widget build(BuildContext context) {
    final spot = TrainingGenerator().generateFromSavedHand(widget.hand);
    final gto = widget.hand.gtoAction;
    final group = widget.hand.rangeGroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hand.name),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReplaySpotWidget(spot: spot),
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
