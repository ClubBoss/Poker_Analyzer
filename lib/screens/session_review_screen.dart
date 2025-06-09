import 'package:flutter/material.dart';

import '../models/error_entry.dart';

class SessionReviewScreen extends StatelessWidget {
  final List<ErrorEntry> errors;

  const SessionReviewScreen({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки сессии'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: errors.isEmpty
          ? const Center(
              child: Text(
                'Ошибок нет',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: errors.length,
              itemBuilder: (context, index) {
                final e = errors[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2B2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.spotTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.situationDescription,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ваше действие: ${e.userAction}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      Text(
                        'Правильное действие: ${e.correctAction}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.aiExplanation,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
