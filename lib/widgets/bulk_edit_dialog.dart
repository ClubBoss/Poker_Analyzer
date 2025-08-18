import 'package:flutter/material.dart';
import 'color_picker_dialog.dart';

Future<(String, Color?)?> showBulkEditDialog(BuildContext context) {
  final controller = TextEditingController();
  Color? color;
  return showDialog<(String, Color?)>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Edit Packs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: color == null
                  ? const Icon(Icons.circle_outlined, color: Colors.white24)
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              title: const Text('Color'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.color_lens),
                    onPressed: () async {
                      final c = await showColorPickerDialog(
                        ctx,
                        initialColor: color ?? Colors.blue,
                      );
                      if (c != null) setState(() => color = c);
                    },
                  ),
                  if (color != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => color = null),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, (controller.text.trim(), color)),
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}
