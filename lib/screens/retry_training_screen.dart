import 'package:flutter/material.dart';

import '../models/error_entry.dart';

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

  void _next() {
    setState(() {
      _showCorrect = false;
      _selectedAction = null;
      _currentIndex = (_currentIndex + 1) % widget.errors.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errors[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retry Mistakes'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                      'Correct Action: ${error.correctAction}',
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.aiExplanation,
                      style: const TextStyle(color: Colors.white70),
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
                            _showCorrect = !_showCorrect;
                          });
                        },
                  child: Text(_showCorrect ? 'Hide' : 'Show Correct Action'),
                ),
                ElevatedButton(
                  onPressed: _next,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
