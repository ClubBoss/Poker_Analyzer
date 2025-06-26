import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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

  String? validateTemplateJson(Map<String, dynamic> data) {
    const strings = ['id', 'name', 'gameType', 'description', 'version'];
    for (final f in strings) {
      if (!data.containsKey(f)) return "отсутствует поле '$f'";
      if (data[f] is! String) return "поле '$f' должно быть строкой";
    }
    if (!data.containsKey('revision')) return "отсутствует поле 'revision'";
    if (data['revision'] is! int) return "поле 'revision' должно быть числом";
    if (!data.containsKey('hands')) return "отсутствует поле 'hands'";
    if (data['hands'] is! List) return "поле 'hands' должно быть списком";
    final v = data['version'] as String;
    final major = int.tryParse(v.split('.').first);
    if (major == null || major != 1) return 'несовместимая версия';
    return null;
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

  void restoreTemplate(TrainingPackTemplate template, int index) {
    final insertIndex = index.clamp(0, _templates.length);
    _templates.insert(insertIndex, template);
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
      if (data is! Map<String, dynamic>) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Неверный формат шаблона: неверный JSON')));
        }
        return null;
      }
      final error = validateTemplateJson(Map<String, dynamic>.from(data));
      if (error != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Неверный формат шаблона: $error')));
        }
        return null;
      }
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

  Future<void> exportTemplateToFile(
      BuildContext context, TrainingPackTemplate template) async {
    try {
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safeName =
          template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safeName.json');
      await file.writeAsString(jsonEncode(template.toJson()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Экспорт завершён'),
            action: SnackBarAction(
              label: 'Открыть',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось экспортировать файл')),
        );
      }
    }
  }
}
