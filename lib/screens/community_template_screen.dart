import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack_template_model.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../services/training_pack_template_storage_service.dart';

class CommunityTemplateScreen extends StatefulWidget {
  const CommunityTemplateScreen({super.key});

  @override
  State<CommunityTemplateScreen> createState() =>
      _CommunityTemplateScreenState();
}

class _CommunityTemplateScreenState extends State<CommunityTemplateScreen> {
  List<TrainingPackTemplateModel> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cloud = context.read<TrainingPackCloudSyncService>();
    final list = await cloud.loadPublicTemplates();
    if (!mounted) return;
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Future<void> _download(TrainingPackTemplateModel tpl) async {
    final storage = context.read<TrainingPackTemplateStorageService>();
    final exists = storage.templates.any((e) => e.id == tpl.id);
    if (exists) {
      await storage.update(tpl);
    } else {
      await storage.add(tpl);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(exists ? 'Обновлено' : 'Загружено')));
  }

  Widget _rating(double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final r = value - i;
        return Icon(
          r >= 1
              ? Icons.star
              : r >= 0.5
              ? Icons.star_half
              : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final t = _templates[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.description.isNotEmpty)
                        Text(
                          t.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      _rating(t.rating),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _download(t),
                  ),
                );
              },
            ),
    );
  }
}
