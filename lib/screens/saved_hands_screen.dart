import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_hand.dart';
import '../services/saved_hand_service.dart';

class SavedHandsScreen extends StatelessWidget {
  const SavedHandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SavedHandService>();
    final savedHands = service.hands;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сохранённые раздачи'),
        centerTitle: true,
      ),
      body: savedHands.isEmpty
          ? const Center(
              child: Text(
                'Нет сохранённых раздач.',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedHands.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final hand = savedHands[index];
                final title = hand.comment ?? 'Раздача ${index + 1}';
                return Dismissible(
                  key: ValueKey(index),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => service.removeAt(index),
                  child: ListTile(
                    tileColor: const Color(0xFF2A2B2E),
                    title: Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
      backgroundColor: const Color(0xFF1B1C1E),
    );
  }
}
