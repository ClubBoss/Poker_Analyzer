import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../helpers/date_utils.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import 'training_pack_screen.dart';
import '../widgets/sync_status_widget.dart';

class SessionDetailScreen extends StatelessWidget {
  final String packName;
  final TrainingSessionResult result;

  const SessionDetailScreen({
    super.key,
    required this.packName,
    required this.result,
  });

  Future<TrainingPack?> _loadPack() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final p = TrainingPack.fromJson(Map<String, dynamic>.from(item));
            if (p.name == packName) return p;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _repeatMistakes(BuildContext context) async {
    final pack = await _loadPack();
    if (pack == null) return;
    final mistakes = result.tasks.where((t) => !t.correct).toList();
    final List<SavedHand> hands = [];
    for (final m in mistakes) {
      try {
        hands.add(pack.hands.firstWhere((h) => h.name == m.question));
      } catch (_) {}
    }
    if (hands.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(
          pack: pack,
          hands: hands,
          mistakeReviewMode: true,
        ),
      ),
    );
  }

  Future<void> _startFullPack(BuildContext context) async {
    final pack = await _loadPack();
    if (pack == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(
          pack: pack,
          hands: pack.hands,
          mistakeReviewMode: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMistakes = result.tasks.any((t) => !t.correct);
    return Scaffold(
      appBar: AppBar(
        title: Text(packName),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(result.date),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (hasMistakes) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _repeatMistakes(context),
                    child: const Text('Повторить ошибочные задачи'),
                  ),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _startFullPack(context),
                  child: const Text('Начать весь пакет заново'),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: result.tasks.isEmpty
                ? const Center(
                    child: Text(
                      'Нет данных по задачам',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.tasks.length,
                    itemBuilder: (context, index) {
                      final t = result.tasks[index];
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
                              t.question,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ваш ответ: ${t.selectedAnswer}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Правильный ответ: ${t.correctAnswer}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.correct ? 'Верно' : 'Неверно',
                              style: TextStyle(
                                color: t.correct ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
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
