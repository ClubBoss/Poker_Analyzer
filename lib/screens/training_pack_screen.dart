import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import 'poker_analyzer_screen.dart';

class TrainingPackScreen extends StatelessWidget {
  final TrainingPack pack;

  const TrainingPackScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final firstHand = pack.hands.isNotEmpty ? pack.hands.first : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(pack.name),
        centerTitle: true,
      ),
      body: firstHand == null
          ? const Center(child: Text('Нет раздач'))
          : PokerAnalyzerScreen(initialHand: firstHand),
      backgroundColor: const Color(0xFF1B1C1E),
    );
  }
}
