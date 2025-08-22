import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagService extends ChangeNotifier {
  static const _prefsKey = 'global_tags';
  static const _defaultColor = '#2196F3';

  List<String> _tags = [];
  final Map<String, String> _colors = {};

  List<String> get tags => List.unmodifiable(_tags);
  String colorOf(String tag) => _colors[tag] ?? _defaultColor;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      try {
        final list = jsonDecode(stored) as List;
        _tags.clear();
        _colors.clear();
        for (final item in list) {
          if (item is Map) {
            final name = item['name']?.toString();
            if (name != null) {
              _tags.add(name);
              _colors[name] = item['color']?.toString() ?? _defaultColor;
            }
          } else {
            final name = item.toString();
            _tags.add(name);
            _colors[name] = _defaultColor;
          }
        }
      } catch (_) {
        _tags = [];
        _colors.clear();
      }
    } else {
      _tags = prefs.getStringList(_prefsKey) ?? [];
      _colors
        ..clear()
        ..addEntries(_tags.map((t) => MapEntry(t, _defaultColor)));
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = [
      for (final name in _tags)
        {'name': name, 'color': _colors[name] ?? _defaultColor},
    ];
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> addTag(String tag, {String color = _defaultColor}) async {
    if (_tags.contains(tag)) return;
    _tags.add(tag);
    _colors[tag] = color;
    await _save();
    notifyListeners();
  }

  Future<void> renameTag(int index, String newTag, {String? color}) async {
    if (index < 0 || index >= _tags.length) return;
    final old = _tags[index];
    if (newTag != old && _tags.contains(newTag)) return;
    _tags[index] = newTag;
    final oldColor = _colors.remove(old) ?? _defaultColor;
    _colors[newTag] = color ?? oldColor;
    await _save();
    notifyListeners();
  }

  Future<void> deleteTag(int index) async {
    if (index < 0 || index >= _tags.length) return;
    final removed = _tags.removeAt(index);
    _colors.remove(removed);
    await _save();
    notifyListeners();
  }

  Future<void> setColor(String tag, String color) async {
    if (!_colors.containsKey(tag)) return;
    _colors[tag] = color;
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
      const encoder = JsonEncoder.withIndent('  ');
      final data = [
        for (final name in _tags)
          {'name': name, 'color': _colors[name] ?? _defaultColor},
      ];
      final jsonStr = encoder.convert(data);
      final fileName = 'tags_${DateTime.now().millisecondsSinceEpoch}.json';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось сохранить файл')));
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
      _tags.clear();
      _colors.clear();
      for (final item in decoded) {
        if (item is Map) {
          final name = item['name']?.toString();
          if (name != null) {
            _tags.add(name);
            _colors[name] = item['color']?.toString() ?? _defaultColor;
          }
        } else {
          final name = item.toString();
          _tags.add(name);
          _colors[name] = _defaultColor;
        }
      }
      await _save();
      notifyListeners();
      if (context.mounted) {
        final name = path.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Импортировано из $name')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка импорта файла')));
      }
    }
  }
}
