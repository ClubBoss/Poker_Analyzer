import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/color_utils.dart';
import '../widgets/color_picker_dialog.dart';
import '../models/training_pack_template.dart';
import '../services/training_pack_storage_service.dart';
import 'training_pack_screen.dart';

class CreatePackFromTemplateScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const CreatePackFromTemplateScreen({super.key, required this.template});

  @override
  State<CreatePackFromTemplateScreen> createState() => _CreatePackFromTemplateScreenState();
}

class _CreatePackFromTemplateScreenState extends State<CreatePackFromTemplateScreen> {
  late TextEditingController _name;
  bool _addTags = true;
  Color _color = Colors.blue;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: 'Новый пак: ${widget.template.name}');
    _color = colorFromHex(widget.template.defaultColor);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final c = await showColorPickerDialog(context, initialColor: _color);
    if (c != null) setState(() => _color = c);
  }

  Future<void> _create() async {
    final service = context.read<TrainingPackStorageService>();
    var pack = await service.createPackFromTemplate(widget.template);
    await service.renamePack(pack, _name.text.trim());
    await service.setColorTag(pack, colorToHex(_color));
    if (!_addTags) await service.setTags(pack, []);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: pack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(backgroundColor: _color),
              title: const Text('Цвет'),
              trailing: IconButton(icon: const Icon(Icons.color_lens), onPressed: _pickColor),
            ),
            CheckboxListTile(
              value: _addTags,
              onChanged: (v) => setState(() => _addTags = v ?? true),
              title: const Text('Добавить теги шаблона'),
            ),
            const Spacer(),
            ElevatedButton(onPressed: _create, child: const Text('Создать')),
          ],
        ),
      ),
    );
  }
}
