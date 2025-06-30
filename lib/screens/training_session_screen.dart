import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_session_service.dart';
import '../widgets/spot_quiz_widget.dart';
import 'session_summary_screen.dart';

class TrainingSessionScreen extends StatelessWidget {
  const TrainingSessionScreen({super.key});

  void _submit(BuildContext context, bool correct) {
    final service = context.read<TrainingSessionService>();
    final spot = service.currentSpot!;
    service.submitResult(spot.id, correct);
    final next = service.nextSpot();
    if (next == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            total: service.totalCount,
            correct: service.correctCount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingSessionService>(
      builder: (context, service, _) {
        final spot = service.currentSpot;
        if (spot == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B1C1E),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Training Session')),
          backgroundColor: const Color(0xFF1B1C1E),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(child: SpotQuizWidget(spot: spot)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _submit(context, true),
                      child: const Text('✅ Correct'),
                    ),
                    ElevatedButton(
                      onPressed: () => _submit(context, false),
                      child: const Text('❌ Mistake'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
