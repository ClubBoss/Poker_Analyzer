import 'package:flutter/material.dart';

class SavedHandsScreen extends StatefulWidget {
  const SavedHandsScreen({super.key});

  @override
  State<SavedHandsScreen> createState() => _SavedHandsScreenState();
}

class _SavedHandsScreenState extends State<SavedHandsScreen> {
  final List<String> _savedHands = [
    'UTG рейз 2bb, MP колл, BB пуш 20bb...',
    'BTN лимп, SB пуш 15bb, BB фолд...',
    'CO рейз 2.5bb, BTN 3бет 7bb, CO колл...',
  ];

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
                return Dismissible(
                  key: Key(_savedHands[index]),
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
                      _savedHands[index],
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