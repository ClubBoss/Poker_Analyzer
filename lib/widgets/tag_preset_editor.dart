import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TagPresetEditor extends StatefulWidget {
  final String? initialName;
  final List<String>? initialTags;
  final Set<String> suggestions;

  const TagPresetEditor({
    super.key,
    this.initialName,
    this.initialTags,
    required this.suggestions,
  });

  @override
  State<TagPresetEditor> createState() => _TagPresetEditorState();
}

class _TagPresetEditorState extends State<TagPresetEditor> {
  late final TextEditingController _controller;
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _selected = {...(widget.initialTags ?? const [])};
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
        widget.initialName == null ? 'Новый пресет' : 'Редактировать пресет',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
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
                  for (final tag in widget.suggestions)
                    CheckboxListTile(
                      value: _selected.contains(tag),
                      title: Text(
                        tag,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setState(() {
                          if (v ?? false) {
                            _selected.add(tag);
                          } else {
                            _selected.remove(tag);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            MapEntry(_controller.text.trim(), _selected.toList()),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
