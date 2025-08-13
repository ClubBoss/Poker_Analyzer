import 'package:flutter/material.dart';
import '../models/training_pack_template.dart';
import '../helpers/color_utils.dart';
import '../helpers/category_translations.dart';

class TemplatePreviewDialog extends StatelessWidget {
  final TrainingPackTemplate template;
  const TemplatePreviewDialog({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final parts = template.version.split('.');
    final version =
        parts.length >= 2 ? '${parts[0]}.${parts[1]}' : template.version;
    final names = [
      for (final h in template.hands.take(5))
        h.name.isEmpty ? 'Без названия' : h.name
    ];
    final rest = template.hands.length - names.length;
    return AlertDialog(
      title: Text(template.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorFromHex(template.defaultColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(translateCategory(template.category) ?? 'Без категории'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Тип: ${template.gameType}'),
            Text('Версия: $version'),
            if (template.author.isNotEmpty) Text('Автор: ${template.author}'),
            const SizedBox(height: 8),
            Text(
                '${template.hands.length} раздач / ${template.tags.length} тегов'),
            const SizedBox(height: 8),
            for (final n in names)
              Text('• $n', overflow: TextOverflow.ellipsis),
            if (rest > 0) Text('… +$rest'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Создать пак'),
        ),
      ],
    );
  }
}
