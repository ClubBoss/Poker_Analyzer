import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/v2/training_pack_template.dart';
import '../../helpers/training_pack_storage.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState extends State<TrainingPackTemplateListScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;
    TrainingPackStorage.load().then((list) {
      if (!mounted) return;
      setState(() {
        _templates.addAll(list);
        _loading = false;
      });
    });
  }

  void _edit(TrainingPackTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: template,
          templates: _templates,
        ),
      ),
    );
    setState(() {});
    TrainingPackStorage.save(_templates);
  }

  void _add() {
    final template = TrainingPackTemplate(id: const Uuid().v4(), name: 'New Pack');
    setState(() => _templates.add(template));
    TrainingPackStorage.save(_templates);
    _edit(template);
  }

  Future<void> _export() async {
    final json = jsonEncode([for (final t in _templates) t.toJson()]);
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates copied to clipboard')),
    );
  }

  Future<void> _import() async {
    final clip = await Clipboard.getData('text/plain');
    if (clip?.text == null || clip!.text!.trim().isEmpty) return;
    List? raw;
    try {
      raw = jsonDecode(clip.text!);
    } catch (_) {}
    if (raw is! List) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      return;
    }
    final imported = [
      for (final m in raw)
        TrainingPackTemplate.fromJson(Map<String, dynamic>.from(m))
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import templates?'),
        content:
            Text('This will add ${imported.length} template(s) to your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() => _templates.addAll(imported));
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} template(s) imported')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Packs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import',
            onPressed: _import,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _export,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          return ListTile(
            title: Text(t.name),
            subtitle: t.description.trim().isEmpty
                ? null
                : Text(
                    t.description.split('\n').first,
                    style: const TextStyle(fontSize: 12),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _edit(t),
                  child: const Text('📝 Edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete pack?'),
                        content: Text('“${t.name}” will be removed.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok ?? false) {
                      setState(() => _templates.removeAt(index));
                      TrainingPackStorage.save(_templates);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
