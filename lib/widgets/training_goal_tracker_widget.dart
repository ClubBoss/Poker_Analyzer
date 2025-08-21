import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/training_session_fingerprint_timeline_service.dart';

/// Widget allowing users to set training goals and track progress.
class TrainingGoalTrackerWidget extends StatefulWidget {
  const TrainingGoalTrackerWidget({super.key});

  @override
  State<TrainingGoalTrackerWidget> createState() =>
      _TrainingGoalTrackerWidgetState();
}

class _TrainingGoalTrackerWidgetState extends State<TrainingGoalTrackerWidget> {
  final TextEditingController _controller = TextEditingController();
  String _unit = 'hands';
  String _period = 'weekly';
  int? _goal;
  int _progress = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _goal = prefs.getInt('training_goal_value');
    _unit = prefs.getString('training_goal_unit') ?? 'hands';
    _period = prefs.getString('training_goal_period') ?? 'weekly';
    if (_goal != null) {
      _controller.text = _goal.toString();
    }
    await _updateProgress();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateProgress() async {
    final service = TrainingSessionFingerprintTimelineService();
    final timeline = await service.generateTimeline();
    final now = DateTime.now();
    DateTime start;
    if (_period == 'weekly') {
      start = now.subtract(Duration(days: now.weekday - 1));
    } else {
      start = DateTime(now.year, now.month, 1);
    }
    final relevant = timeline.where((e) => !e.date.isBefore(start)).toList();
    var total = 0;
    for (final s in relevant) {
      total += _unit == 'hands' ? s.handCount : s.sessionCount;
    }
    setState(() {
      _progress = total;
    });
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text);
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('training_goal_value', value);
    await prefs.setString('training_goal_unit', _unit);
    await prefs.setString('training_goal_period', _period);
    setState(() {
      _goal = value;
    });
    await _updateProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final goal = _goal;
    final progressFraction = goal == null || goal == 0
        ? 0.0
        : (_progress / goal).clamp(0.0, 1.0);
    final periodText = _period == 'weekly' ? 'this week' : 'this month';
    final unitText = _unit == 'hands' ? 'hands' : 'sessions';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Goal'),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _unit,
              items: const [
                DropdownMenuItem(value: 'hands', child: Text('Hands')),
                DropdownMenuItem(value: 'sessions', child: Text('Sessions')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _unit = v);
              },
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _period = v);
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _save, child: const Text('Set')),
          ],
        ),
        if (goal != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progressFraction),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('$_progress / $goal $unitText $periodText'),
              if (_progress < goal) ...[
                const SizedBox(width: 4),
                const Icon(Icons.flag, size: 16, color: Colors.orange),
              ],
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
