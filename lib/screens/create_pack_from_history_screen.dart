import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../helpers/date_utils.dart';
import '../helpers/training_pack_storage.dart';
import '../services/template_storage_service.dart';
import '../widgets/sync_status_widget.dart';
import '../models/v2/training_pack_template.dart';
import '../utils/snackbar_util.dart';

class CreatePackFromHistoryScreen extends StatefulWidget {
  const CreatePackFromHistoryScreen({super.key});

  @override
  State<CreatePackFromHistoryScreen> createState() => _CreatePackFromHistoryScreenState();
}

class _CreatePackFromHistoryScreenState extends State<CreatePackFromHistoryScreen> {
  final TextEditingController _name = TextEditingController(text: 'Новый пак');
  final TextEditingController _search = TextEditingController();
  final Set<SavedHand> _selected = {};

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  List<SavedHand> _filter(List<SavedHand> list) {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return list;
    return [
      for (final h in list)
        if (h.name.toLowerCase().contains(q) ||
            h.tags.any((t) => t.toLowerCase().contains(q)) ||
            (h.comment?.toLowerCase().contains(q) ?? false))
          h
    ];
  }

  void _toggle(SavedHand h) {
    setState(() {
      if (_selected.contains(h)) {
        _selected.remove(h);
      } else {
        _selected.add(h);
      }
    });
  }

  Future<TrainingPackTemplate> _buildPack() async {
    final manager = context.read<SavedHandManagerService>();
    final name = _name.text.trim().isEmpty ? 'Новый пак' : _name.text.trim();
    return manager.createPack(name, _selected.toList());
  }

  Future<void> _create() async {
    if (_selected.isEmpty) return;
    final tpl = await _buildPack();
    final list = await TrainingPackStorage.load();
    list.add(tpl);
    await TrainingPackStorage.save(list);
    context.read<TemplateStorageService>().addTemplate(tpl);
    if (!mounted) return;
    Navigator.pop(context);
    SnackbarUtil.showMessage(context, 'Пак "${tpl.name}" создан');
  }

  Future<void> _export() async {
    if (_selected.isEmpty) return;
    final tpl = await _buildPack();
    final fileName = '${tpl.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.json';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Pack',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return;
    final file = File(path);
    await file.writeAsString(jsonEncode(tpl.toJson()));
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final filtered = _filter(hands);
    return Scaffold(
      appBar: AppBar(title: const Text('Пак из истории'), actions: [SyncStatusIcon.of(context)]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final h = filtered[i];
                  final title = h.name.isEmpty ? 'Без названия' : h.name;
                  return CheckboxListTile(
                    value: _selected.contains(h),
                    onChanged: (_) => _toggle(h),
                    title: Text('$title • ${formatLongDate(h.savedAt)}'),
                    subtitle: h.tags.isEmpty ? null : Text(h.tags.join(', ')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Выбрано: ${_selected.length}'),
                Row(
                  children: [
                    ElevatedButton(onPressed: _selected.isEmpty ? null : _export, child: const Text('Экспорт')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _selected.isEmpty ? null : _create, child: const Text('Создать')),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
