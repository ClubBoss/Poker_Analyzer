import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../services/daily_challenge_service.dart';
import '../widgets/training_spot_diagram.dart';
import '../screens/daily_challenge_result_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  final TrainingSpot spot;
  const DailyChallengeScreen({super.key, required this.spot});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  Future<void> _choose(String action) async {
    final updated = widget.spot.copyWith(userAction: action);
    await DailyChallengeService.instance.markCompleted();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DailyChallengeResultScreen(spot: updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge'), centerTitle: true),
      backgroundColor: const Color(0xFF121212),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TrainingSpotDiagram(
            spot: spot,
            size: MediaQuery.of(context).size.width - 32,
          ),
          const SizedBox(height: 16),
          const Text('Ваше действие?', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: spot.actionType == SpotActionType.callPush
                ? [
                    ElevatedButton(
                      onPressed: () => _choose('CALL'),
                      child: const Text('CALL'),
                    ),
                    ElevatedButton(
                      onPressed: () => _choose('FOLD'),
                      child: const Text('FOLD'),
                    ),
                  ]
                : [
                    ElevatedButton(
                      onPressed: () => _choose('PUSH'),
                      child: const Text('PUSH'),
                    ),
                    ElevatedButton(
                      onPressed: () => _choose('FOLD'),
                      child: const Text('FOLD'),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}
