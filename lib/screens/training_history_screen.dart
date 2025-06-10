import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_result.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  final List<TrainingResult> _history = [];
  double _averageAccuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('training_history') ?? [];
    final List<TrainingResult> loaded = [];
    for (final item in stored) {
      try {
        final data = jsonDecode(item);
        if (data is Map<String, dynamic>) {
          loaded.add(TrainingResult.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (_) {}
    }
    setState(() {
      _history
        ..clear()
        ..addAll(loaded.reversed);
      _averageAccuracy = _history.isNotEmpty
          ? _history
                  .map((e) => e.accuracy)
                  .reduce((a, b) => a + b) /
              _history.length
          : 0.0;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('training_history');
    setState(() {
      _history.clear();
      _averageAccuracy = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _clearHistory,
            child: const Text('Clear History'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _history.isEmpty
          ? const Center(
              child: Text(
                'No history available.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Average Accuracy: ${_averageAccuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final result = _history[index];
                      final accuracy = result.accuracy.toStringAsFixed(1);
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2B2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            _formatDate(result.date),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Correct: ${result.correct} / ${result.total}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            '$accuracy%',
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _history.length,
                  ),
                ),
              ],
            ),
    );
  }
}
