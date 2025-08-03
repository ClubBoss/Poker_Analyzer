import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

Future<MapEntry<String, List<String>>?> showTagPresetDialog(
  BuildContext context, {
  String? initialName,
  List<String>? initialTags,
  required Set<String> suggestions,
}) async {
  final controller = TextEditingController(text: initialName ?? '');
  final local = <String>{...(initialTags ?? [])};
  final result = await showDialog<MapEntry<String, List<String>>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          initialName == null ? 'Новый пресет' : 'Редактировать пресет',
          style: const TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Название',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final tag in suggestions)
                          CheckboxListTile(
                            value: local.contains(tag),
                            title: Text(tag,
                                style: const TextStyle(color: Colors.white)),
                            onChanged: (v) {
                              setStateDialog(() {
                                if (v ?? false) {
                                  local.add(tag);
                                } else {
                                  local.remove(tag);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
                context, MapEntry(controller.text.trim(), local.toList())),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
  return result;
}
