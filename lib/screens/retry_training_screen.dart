import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../theme/app_colors.dart';
import '../widgets/common/explanation_text.dart';
import '../widgets/common/summary_card.dart';

import '../models/error_entry.dart';
import '../models/training_result.dart';
import '../widgets/sync_status_widget.dart';

class RetryTrainingScreen extends StatefulWidget {
  final List<ErrorEntry> errors;

  const RetryTrainingScreen({super.key, required this.errors});

  @override
  State<RetryTrainingScreen> createState() => _RetryTrainingScreenState();
}

class _RetryTrainingScreenState extends State<RetryTrainingScreen> {
  int _currentIndex = 0;
  bool _showCorrect = false;
  String? _selectedAction;
  int _correctCount = 0;
  int _totalAnswered = 0;

  Future<void> _saveResult() async {
    final accuracy =
        _totalAnswered > 0 ? _correctCount * 100 / _totalAnswered : 0.0;
    final result = TrainingResult(
      date: DateTime.now(),
      total: _totalAnswered,
      correct: _correctCount,
      accuracy: accuracy,
      tags: const [],
      notes: null,
    );
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('training_history') ?? [];
    history.add(jsonEncode(result.toJson()));
    await prefs.setStringList('training_history', history);
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _totalAnswered = 0;
      _showCorrect = false;
      _selectedAction = null;
    });
  }

  void _next() {
    setState(() {
      _showCorrect = false;
      _selectedAction = null;
      _currentIndex = (_currentIndex + 1) % widget.errors.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = _totalAnswered == widget.errors.length;
    final error = widget.errors[_currentIndex];

    Widget body;
    if (completed) {
      final accuracy =
          _totalAnswered > 0 ? _correctCount * 100 / _totalAnswered : 0.0;
      final message = _correctCount == _totalAnswered
          ? 'Perfect!'
          : accuracy >= 80
              ? 'Great effort!'
              : 'Keep training!';

      body = Column(
        children: [
          const Spacer(),
          SummaryCard(
            correctCount: _correctCount,
            totalAnswered: _totalAnswered,
            message: message,
            onRetry: _restart,
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Mistakes to retry: ${widget.errors.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: widget.errors.isNotEmpty
                ? _totalAnswered / widget.errors.length
                : 0,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.green),
          ),
          const SizedBox(height: 4),
          Text(
            '$_totalAnswered of ${widget.errors.length} completed',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.spotTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.situationDescription,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedAction,
                  dropdownColor: AppColors.cardBackground,
                  hint: const Text(
                    'Select your action',
                    style: TextStyle(color: Colors.white70),
                  ),
                  iconEnabledColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'Fold', child: Text('Fold')),
                    DropdownMenuItem(value: 'Call', child: Text('Call')),
                    DropdownMenuItem(
                      value: 'Raise small',
                      child: Text('Raise small'),
                    ),
                    DropdownMenuItem(
                      value: 'Raise big',
                      child: Text('Raise big'),
                    ),
                    DropdownMenuItem(value: 'All-in', child: Text('All-in')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAction = value;
                    });
                  },
                ),
                if (_showCorrect) ...[
                  const SizedBox(height: 8),
                  ExplanationText(
                    selectedAction: _selectedAction ?? '',
                    correctAction: error.correctAction,
                    explanation: error.aiExplanation,
                    evLoss: null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _selectedAction == null
                    ? null
                    : () {
                        setState(() {
                          if (!_showCorrect) {
                            _totalAnswered++;
                            if (_selectedAction == error.correctAction) {
                              _correctCount++;
                            }
                          }
                          _showCorrect = !_showCorrect;
                        });
                        if (_totalAnswered == widget.errors.length) {
                          _saveResult();
                        }
                      },
                child: Text(_showCorrect ? 'Hide' : 'Show Correct Action'),
              ),
              ElevatedButton(onPressed: _next, child: const Text('Next')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Correct: $_correctCount / $_totalAnswered',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retry Mistakes'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: AppColors.background,
      body: Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }
}
