import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../services/daily_challenge_meta_service.dart';
import 'master_mode_screen.dart';
import '../widgets/streak_badge_widget.dart';

class DailyChallengeResultScreen extends StatefulWidget {
  final TrainingSpot spot;
  const DailyChallengeResultScreen({super.key, required this.spot});

  @override
  State<DailyChallengeResultScreen> createState() =>
      _DailyChallengeResultScreenState();
}

class _DailyChallengeResultScreenState
    extends State<DailyChallengeResultScreen> {
  @override
  void initState() {
    super.initState();
    DailyChallengeMetaService.instance.markResultShown();
  }

  double? get _ev =>
      widget.spot.actions.isNotEmpty ? widget.spot.actions.first.ev : null;

  String get _bestAction => widget.spot.recommendedAction ?? '-';

  String? get _explanation => widget.spot.explanation;

  @override
  Widget build(BuildContext context) {
    final evText = _ev != null ? _ev!.toStringAsFixed(2) : '-';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат челленджа'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StreakBadgeWidget(),
            Text('EV: $evText', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Лучшее действие: $_bestAction',
              style: const TextStyle(color: Colors.white),
            ),
            if (_explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                _explanation!,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MasterModeScreen()),
                  (route) => false,
                );
              },
              child: const Text('🔁 Вернуться в мастер-режим'),
            ),
          ],
        ),
      ),
    );
  }
}
