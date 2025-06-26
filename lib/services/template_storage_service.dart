import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/training_pack_template.dart';

class TemplateStorageService extends ChangeNotifier {
  final List<TrainingPackTemplate> _templates = [];
  List<TrainingPackTemplate> get templates => List.unmodifiable(_templates);

  void _resort() {
    _templates.sort((a, b) {
      if (a.gameType != b.gameType) return a.gameType.compareTo(b.gameType);
      final rev = b.revision.compareTo(a.revision);
      return rev == 0 ? a.name.compareTo(b.name) : rev;
    });
  }

  void addTemplate(TrainingPackTemplate template) {
    _templates.add(template);
    _resort();
    notifyListeners();
  }

  void removeTemplate(TrainingPackTemplate template) {
    if (template.isBuiltIn) return;
    _templates.remove(template);
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final manifest =
          jsonDecode(await rootBundle.loadString('AssetManifest.json')) as Map;
      final paths = manifest.keys.where((e) =>
          e.startsWith('assets/training_templates/') && e.endsWith('.json'));
      _templates.clear();
      for (final p in paths) {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          _templates.add(TrainingPackTemplate.fromJson(data));
        }
      }
      _resort();
    } catch (_) {}
    notifyListeners();
  }

  Future<TrainingPackTemplate?> importTemplateFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! Map<String, dynamic>) return null;
      if (!data.containsKey('name') || !data.containsKey('hands')) return null;
      var template =
          TrainingPackTemplate.fromJson(Map<String, dynamic>.from(data));
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        final existing = _templates[index];
        if (template.revision > existing.revision) {
          final replace = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Найдена новая ревизия. Обновить?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Пропустить'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Обновить'),
                ),
              ],
            ),
          );
          if (replace == true) {
            _templates[index] = template;
            notifyListeners();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Шаблон обновлён'),
                  action: SnackBarAction(
                    label: 'Отмена',
                    onPressed: () {
                      _templates[index] = existing;
                      notifyListeners();
                    },
                  ),
                ),
              );
            }
            return template;
          }
          return null;
        } else if (template.revision == existing.revision) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Такой шаблон уже есть')),
            );
          }
          return null;
        } else {
          final action = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Импортировать старую версию?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'skip'),
                  child: const Text('Пропустить'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'keep'),
                  child: const Text('Оставить обе'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'replace'),
                  child: const Text('Заменить'),
                ),
              ],
            ),
          );
          if (action == 'replace') {
            _templates[index] = template;
            notifyListeners();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Шаблон обновлён'),
                  action: SnackBarAction(
                    label: 'Отмена',
                    onPressed: () {
                      _templates[index] = existing;
                      notifyListeners();
                    },
                  ),
                ),
              );
            }
            return template;
          } else if (action == 'keep') {
            template = TrainingPackTemplate(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: template.name,
              gameType: template.gameType,
              description: template.description,
              hands: template.hands,
              version: template.version,
              author: template.author,
              revision: template.revision,
              createdAt: template.createdAt,
              updatedAt: template.updatedAt,
              isBuiltIn: template.isBuiltIn,
            );
          } else {
            return null;
          }
        }
      }
      _templates.add(template);
      _resort();
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Шаблон импортирован')),
        );
      }
      return template;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка импорта файла')),
        );
      }
      return null;
    }
  }
}
