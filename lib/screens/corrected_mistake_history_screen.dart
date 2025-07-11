import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import 'mistake_detail_screen.dart';

class CorrectedMistakeHistoryScreen extends StatelessWidget {
  const CorrectedMistakeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final corrected = [for (final h in hands) if (h.corrected) h]
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Исправленные ошибки'),
        centerTitle: true,
      ),
      body: corrected.isEmpty
          ? const Center(
              child: Text('Нет данных',
                  style: TextStyle(color: Colors.white70)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: corrected.length,
              itemBuilder: (context, index) {
                final h = corrected[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MistakeDetailScreen(hand: h),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.heroPosition,
                                  style: const TextStyle(color: Colors.white)),
                              if (h.evLossRecovered != null)
                                Text(
                                  '+${h.evLossRecovered!.toStringAsFixed(2)} EV',
                                  style: const TextStyle(
                                      color: Colors.greenAccent, fontSize: 12),
                                ),
                              if (h.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children: [
                                      for (final t in h.tags)
                                        Chip(
                                          label: Text(t),
                                          backgroundColor:
                                              const Color(0xFF3A3B3E),
                                          labelStyle:
                                              const TextStyle(color: Colors.white),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
