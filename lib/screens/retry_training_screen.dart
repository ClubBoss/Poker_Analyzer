import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/error_entry.dart';
import '../models/training_result.dart';

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
    final accuracy = _totalAnswered > 0
        ? _correctCount * 100 / _totalAnswered
        : 0.0;
    final result = TrainingResult(
      date: DateTime.now(),
      total: _totalAnswered,
      correct: _correctCount,
      accuracy: accuracy,
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
      final accuracy = _totalAnswered > 0
          ? _correctCount * 100 / _totalAnswered
          : 0.0;
      final message = _correctCount == _totalAnswered
          ? 'Perfect!'
          : accuracy >= 80
              ? 'Great effort!'
              : 'Keep training!';

      body = Column(
        children: [
          const Spacer(),
          Card(
            color: const Color(0xFF2A2B2E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Correct: $_correctCount / $_totalAnswered',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _restart,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2B2E),
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
                  dropdownColor: const Color(0xFF2A2B2E),
                  hint: const Text(
                    'Select your action',
                    style: TextStyle(color: Colors.white70),
                  ),
                  iconEnabledColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'Fold', child: Text('Fold')),
                    DropdownMenuItem(value: 'Call', child: Text('Call')),
                    DropdownMenuItem(value: 'Raise small', child: Text('Raise small')),
                    DropdownMenuItem(value: 'Raise big', child: Text('Raise big')),
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
                  Text(
                    'Your Action: $_selectedAction',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAction == error.correctAction
                        ? '✅ Correct'
                        : '❌ Mistake',
                    style: TextStyle(
                      color: _selectedAction == error.correctAction
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correct Action: ${error.correctAction}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Explanation: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: error.aiExplanation,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
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
              ElevatedButton(
                onPressed: _next,
                child: const Text('Next'),
              ),
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
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}
