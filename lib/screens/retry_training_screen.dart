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

  void _next() {
    setState(() {
      _showCorrect = false;
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
                  if (_showCorrect) ...[
                    const SizedBox(height: 8),
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
                  onPressed: () {
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
