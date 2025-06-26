import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../helpers/color_utils.dart';

import '../models/training_pack_template.dart';
import '../models/saved_hand.dart';
import '../services/training_pack_storage_service.dart';

class CreatePackFromTemplateScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const CreatePackFromTemplateScreen({super.key, required this.template});

  @override
  State<CreatePackFromTemplateScreen> createState() => _CreatePackFromTemplateScreenState();
}

class _CreatePackFromTemplateScreenState extends State<CreatePackFromTemplateScreen> {
  late List<SavedHand> _selected;
  final TextEditingController _category = TextEditingController();
  Color _color = Colors.blue;

  Future<void> _pickColor() async {
    Color pickerColor = _color;
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Цвет пакета'),
        content: BlockPicker(
          pickerColor: pickerColor,
          onColorChanged: (c) => pickerColor = c,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, pickerColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _color = result);
  }

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.template.hands);
    _category.text = widget.template.category ?? '';
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

  Future<void> _create() async {
    if (_selected.isEmpty) return;
    await context.read<TrainingPackStorageService>().createFromTemplateWithOptions(
      widget.template,
      hands: _selected,
      categoryOverride: _category.text.trim(),
      colorTag: colorToHex(_color),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пакет создан из шаблона')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [IconButton(onPressed: _create, icon: const Icon(Icons.check))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Категория (опц.)'),
            ),
          ),
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
              ),
            ),
            title: const Text('Цвет пакета'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _pickColor,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.template.hands.length,
              itemBuilder: (_, i) {
                final h = widget.template.hands[i];
                return CheckboxListTile(
                  value: _selected.contains(h),
                  onChanged: (_) => _toggle(h),
                  title: Text(h.name.isNotEmpty ? h.name : 'Раздача ${i + 1}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
