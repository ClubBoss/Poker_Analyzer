import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';
import '../services/evaluation_executor_service.dart';
import '../widgets/sync_status_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _evaluated;
  late int _correct;

  void _load() {
    final service = EvaluationExecutorService();
    _evaluated = service.totalEvaluated;
    _correct = service.totalCorrect;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _reset() async {
    await EvaluationExecutorService().resetAccuracy();
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>().count;
    final acc = _evaluated == 0 ? 0 : _correct / _evaluated;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Streak: $streak',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Accuracy: ${(acc * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reset,
              child: const Text('Reset Accuracy'),
            ),
          ],
        ),
      ),
    );
  }
}
