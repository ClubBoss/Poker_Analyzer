import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagService extends ChangeNotifier {
  static const _prefsKey = 'global_tags';

  List<String> _tags = [];

  List<String> get tags => List.unmodifiable(_tags);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _tags = prefs.getStringList(_prefsKey) ?? [];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _tags);
  }

  Future<void> addTag(String tag) async {
    if (_tags.contains(tag)) return;
    _tags.add(tag);
    await _save();
    notifyListeners();
  }

  Future<void> renameTag(int index, String newTag) async {
    if (index < 0 || index >= _tags.length) return;
    if (_tags.contains(newTag)) return;
    _tags[index] = newTag;
    await _save();
    notifyListeners();
  }

  Future<void> deleteTag(int index) async {
    if (index < 0 || index >= _tags.length) return;
    _tags.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> reorderTags(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _tags.removeAt(oldIndex);
    _tags.insert(newIndex, item);
    await _save();
    notifyListeners();
  }

  Future<void> exportToFile(BuildContext context) async {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      final jsonStr = encoder.convert(_tags);
      final fileName =
          'tags_${DateTime.now().millisecondsSinceEpoch}.json';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Tags',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath == null) return;
      final file = File(savePath);
      await file.writeAsString(jsonStr);
      if (context.mounted) {
        final name = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл сохранён: $name')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить файл')),
        );
      }
    }
  }

  Future<void> importFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! List) throw const FormatException();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Заменить текущие теги?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Заменить'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      _tags = decoded.map((e) => e.toString()).toSet().toList();
      await _save();
      notifyListeners();
      if (context.mounted) {
        final name = path.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Импортировано из $name')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка импорта файла')),
        );
      }
    }
  }
}
