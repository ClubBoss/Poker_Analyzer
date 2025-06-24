import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_pack_screen.dart';

class CloudTrainingSessionDetailsScreen extends StatelessWidget {
  final CloudTrainingSession session;

  const CloudTrainingSessionDetailsScreen({super.key, required this.session});

  Future<void> _exportMarkdown(BuildContext context) async {
    if (session.results.isEmpty) return;
    final buffer = StringBuffer();
    for (final r in session.results) {
      final result = r.correct ? 'correct' : 'wrong';
      buffer.writeln(
          '- ${r.name}: user `${r.userAction}`, expected `${r.expected}` - $result');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cloud_session.md');
    await file.writeAsString(buffer.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: cloud_session.md')),
      );
    }
  }

  Future<void> _repeatSession(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final Map<String, SavedHand> map = {
      for (final h in manager.hands) h.name: h
    };
    final List<SavedHand> hands = [];
    for (final r in session.results) {
      final hand = map[r.name];
      if (hand != null) hands.add(hand);
    }
    if (hands.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Раздачи не найдены')),
        );
      }
      return;
    }
    final pack = TrainingPack(
      name: 'Повторение',
      description: '',
      hands: hands,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(pack: pack, hands: hands),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formatDateTime(session.date)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed:
                session.results.isEmpty ? null : () => _exportMarkdown(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: session.results.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _repeatSession(context),
                    child: const Text('Повторить'),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
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
                                      style:
                                          const TextStyle(color: Colors.white70)),
                                  Text('Ожидалось: ${r.expected}',
                                      style:
                                          const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
