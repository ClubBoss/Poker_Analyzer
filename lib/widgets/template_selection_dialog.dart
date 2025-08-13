import 'package:flutter/material.dart';

import '../models/training_pack_template.dart';

class TemplateSelectionDialog extends StatefulWidget {
  final List<TrainingPackTemplate> templates;
  const TemplateSelectionDialog({super.key, required this.templates});

  @override
  State<TemplateSelectionDialog> createState() =>
      _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<TemplateSelectionDialog> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final t in widget.templates)
        if (t.name.toLowerCase().contains(_filter.toLowerCase()) ||
            t.description.toLowerCase().contains(_filter.toLowerCase()))
          t
    ];
    return AlertDialog(
      title: const Text('Выберите шаблон'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final t = visible[index];
                  return ListTile(
                    title: Text(t.name),
                    subtitle: Text(t.description),
                    onTap: () => Navigator.pop(context, t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
