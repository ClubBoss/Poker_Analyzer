import 'package:flutter/material.dart';
import '../models/saved_hand.dart';

class SavedHandsScreen extends StatefulWidget {
  const SavedHandsScreen({super.key});

  @override
  State<SavedHandsScreen> createState() => _SavedHandsScreenState();
}

class _SavedHandsScreenState extends State<SavedHandsScreen> {
  final List<SavedHand> _savedHands = [];

  void _deleteHand(int index) {
    setState(() {
      _savedHands.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сохранённые раздачи'),
        centerTitle: true,
      ),
      body: _savedHands.isEmpty
          ? const Center(
              child: Text(
                'Нет сохранённых раздач.',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _savedHands.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final hand = _savedHands[index];
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
                  onDismissed: (_) => _deleteHand(index),
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
