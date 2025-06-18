import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../services/training_pack_storage_service.dart';
import 'create_pack_screen.dart';

class EditPackScreen extends StatelessWidget {
  const EditPackScreen({super.key});

  Future<void> _openEditor(BuildContext context, TrainingPack pack) async {
    final service = context.read<TrainingPackStorageService>();
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePackScreen(initialPack: pack),
      ),
    );
    if (updated is TrainingPack) {
      await service.removePack(pack);
      await service.addPack(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать тренировку'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: packs.isEmpty
          ? const Center(child: Text('Нет доступных пакетов'))
          : ListView.builder(
              itemCount: packs.length,
              itemBuilder: (context, index) {
                final pack = packs[index];
                return ListTile(
                  title: Text(pack.name),
                  subtitle: Text(pack.description),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _openEditor(context, pack),
                );
              },
            ),
    );
  }
}
