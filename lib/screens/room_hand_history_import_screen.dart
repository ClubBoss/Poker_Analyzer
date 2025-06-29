import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../services/room_hand_history_importer.dart';
import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';
import 'room_hand_history_editor_screen.dart';

class RoomHandHistoryImportScreen extends StatefulWidget {
  final TrainingPack pack;
  const RoomHandHistoryImportScreen({super.key, required this.pack});

  @override
  State<RoomHandHistoryImportScreen> createState() => _RoomHandHistoryImportScreenState();
}

class _RoomHandHistoryImportScreenState extends State<RoomHandHistoryImportScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SavedHand> _hands = [];
  late TrainingPack _pack;
  RoomHandHistoryImporter? _importer;

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
    RoomHandHistoryImporter.create().then((i) {
      if (mounted) setState(() => _importer = i);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty || _importer == null) return;
    final parsed = _importer!.parse(text);
    setState(() => _hands = parsed);
  }

  Future<void> _preview(SavedHand hand) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(hand.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${hand.heroPosition} • ${hand.numberOfPlayers}p', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Actions: ${hand.actions.length}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<void> _add(SavedHand hand) async {
    final updated = TrainingPack(
      name: _pack.name,
      description: _pack.description,
      category: _pack.category,
      gameType: _pack.gameType,
      colorTag: _pack.colorTag,
      isBuiltIn: _pack.isBuiltIn,
      tags: _pack.tags,
      hands: [..._pack.hands, hand],
      spots: _pack.spots,
      difficulty: _pack.difficulty,
      history: _pack.history,
    );
    await context.read<TrainingPackStorageService>().updatePack(_pack, updated);
    setState(() => _pack = updated);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomHandHistoryEditorScreen(pack: _pack, hands: [hand])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pack.name), centerTitle: true),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Hand history'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _parse, child: const Text('Parse')),
            const SizedBox(height: 12),
            Expanded(
              child: _hands.isEmpty
                  ? const Center(child: Text('No hands'))
                  : ListView.builder(
                      itemCount: _hands.length,
                      itemBuilder: (_, i) {
                        final h = _hands[i];
                        return Card(
                          color: AppColors.cardBackground,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(h.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${h.heroPosition} • ${h.numberOfPlayers}p', style: const TextStyle(color: Colors.white70)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye, color: Colors.white70),
                                  onPressed: () => _preview(h),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white70),
                                  onPressed: () => _add(h),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
