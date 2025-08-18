import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/pack_editor_snapshot.dart';

part 'pack_editor_toolbar.dart';
part 'pack_editor_overlays.dart';

class PackEditorCommand {
  final String id;
  final String label;
  final LogicalKeySet? shortcut;
  final VoidCallback action;

  const PackEditorCommand(this.id, this.label, this.shortcut, this.action);
}

class PackEditorCore extends ChangeNotifier {
  final TrainingPack pack;
  final List<SavedHand> hands;
  final List<PackEditorCommand> commands = [];
  final List<PackEditorSnapshot> snapshots = [];

  PackEditorCore(this.pack) : hands = List<SavedHand>.from(pack.hands);

  void registerCommand(PackEditorCommand command) {
    commands.add(command);
  }

  void addHand(SavedHand hand) {
    hands.add(hand);
    notifyListeners();
  }

  void saveSnapshot([String? name]) {
    snapshots.add(
      PackEditorSnapshot(
        name: name ?? 'Snapshot ${snapshots.length + 1}',
        hands: List<SavedHand>.from(hands),
        views: const [],
        filters: const {},
      ),
    );
    notifyListeners();
  }
}

class PackEditorScreen extends StatelessWidget {
  final TrainingPack pack;
  const PackEditorScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final core = PackEditorCore(pack);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => core.saveSnapshot(),
          ),
        ],
      ),
      body: PackEditorToolbar(core: core),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showImportExportDialog(context, core),
        child: const Icon(Icons.file_upload),
      ),
    );
  }
}
