import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';
import 'create_pack_from_template_screen.dart';
import 'training_pack_template_editor_screen.dart';

class MyTrainingPacksScreen extends StatefulWidget {
  const MyTrainingPacksScreen({super.key});

  @override
  State<MyTrainingPacksScreen> createState() => _MyTrainingPacksScreenState();
}

class _MyTrainingPacksScreenState extends State<MyTrainingPacksScreen> {
  String _filter = 'All';

  List<TrainingPackTemplateModel> _sorted(
      List<TrainingPackTemplateModel> list) {
    list.sort((a, b) {
      final ad = a.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    if (_filter == 'NEW only') {
      final cutoff = DateTime.now().subtract(const Duration(hours: 48));
      list.retainWhere((t) =>
          t.lastGeneratedAt != null && t.lastGeneratedAt!.isAfter(cutoff));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final templates = _sorted(List.from(
        context.watch<TrainingPackTemplateStorageService>().templates));
    return Scaffold(
      appBar: AppBar(title: const Text('Мои паки'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _filter,
              onChanged: (v) => setState(() => _filter = v ?? 'All'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'NEW only', child: Text('NEW only')),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: templates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = templates[index];
                final date = t.lastGeneratedAt;
                return ListTile(
                  title: Text(t.name),
                  subtitle: date == null
                      ? null
                      : Text(date.toLocal().toString().split('.').first),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePackFromTemplateScreen(
                            template: t,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () async {
                    final model =
                        await Navigator.push<TrainingPackTemplateModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TrainingPackTemplateEditorScreen(initial: t),
                      ),
                    );
                    if (model != null && mounted) {
                      await context
                          .read<TrainingPackTemplateStorageService>()
                          .update(model);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
