import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../theme/app_colors.dart';
import '../widgets/training_spot_diagram.dart';
import '../models/action_entry.dart';
import '../widgets/sync_status_widget.dart';

class TrainingReviewScreen extends StatelessWidget {
  final String title;
  final TrainingSpot spot;

  const TrainingReviewScreen({
    super.key,
    required this.title,
    required this.spot,
  });

  Color? _colorForAdvice(String advice) {
    switch (advice.toUpperCase()) {
      case 'PUSH':
        return Colors.green;
      case 'FOLD':
        return Colors.red;
      case 'CALL':
        return Colors.blue;
      default:
        return null;
    }
  }

  Widget _buildAction(ActionEntry entry) {
    String label = entry.action;
    if (entry.amount != null) {
      label += ' ${entry.amount}';
    }

    if (entry.playerIndex < spot.stacks.length) {
      final stack = spot.stacks[entry.playerIndex];
      final bb = (stack / 12.5).round();
      label += ' $stack ($bb BB)';
    }

    String? advice;
    if (spot.strategyAdvice != null &&
        entry.playerIndex < spot.strategyAdvice!.length) {
      advice = spot.strategyAdvice![entry.playerIndex];
    }

    final adviceColor = advice != null ? _colorForAdvice(advice) : null;

    double? equity;
    if (spot.equities != null && entry.playerIndex < spot.equities!.length) {
      equity = spot.equities![entry.playerIndex].toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('P${entry.playerIndex + 1}: $label'),
        if (equity != null)
          Text(
            'Equity: ${equity.round()}%',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        if (advice != null && adviceColor != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              advice.toUpperCase(),
              style: TextStyle(
                color: adviceColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentRows = <Widget>[];
    if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty) {
      tournamentRows.add(
        Text(
          'ID: ${spot.tournamentId}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (spot.buyIn != null) {
      tournamentRows.add(
        Text(
          'Buy-In: ${spot.buyIn}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (spot.totalPrizePool != null) {
      tournamentRows.add(
        Text(
          'Prize Pool: ${spot.totalPrizePool}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (spot.numberOfEntrants != null) {
      tournamentRows.add(
        Text(
          'Entrants: ${spot.numberOfEntrants}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (spot.gameType != null && spot.gameType!.isNotEmpty) {
      tournamentRows.add(
        Text(
          'Game: ${spot.gameType}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final stackRows = <Widget>[];
    for (int i = 0; i < spot.stacks.length; i++) {
      final stack = spot.stacks[i];
      final bb = (stack / 12.5).round();
      stackRows.add(
        Text(
          'Stack: $stack ($bb BB)',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Review'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            TrainingSpotDiagram(
              spot: spot,
              size: MediaQuery.of(context).size.width - 32,
            ),
            const SizedBox(height: 16),
            if (stackRows.isNotEmpty) ...[
              const Text(
                'Stacks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...stackRows,
              const SizedBox(height: 8),
            ],
            if (tournamentRows.isNotEmpty) ...[
              const Text(
                'Tournament Info',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...tournamentRows,
              const SizedBox(height: 8),
            ],
            for (final a in spot.actions) _buildAction(a),
          ],
        ),
      ),
    );
  }
}
