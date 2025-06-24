import 'package:flutter/material.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';

class CloudTrainingSessionDetailsScreen extends StatelessWidget {
  final CloudTrainingSession session;

  const CloudTrainingSessionDetailsScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formatDateTime(session.date)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: session.results.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.results.length,
              itemBuilder: (context, index) {
                final r = session.results[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2B2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        r.correct ? Icons.check : Icons.close,
                        color: r.correct ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Вы: ${r.userAction}',
                                style: const TextStyle(color: Colors.white70)),
                            Text('Ожидалось: ${r.expected}',
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
