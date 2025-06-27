import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Set<int> _selected = {};
  SharedPreferences? _prefs;
  static const _colorKey = 'template_last_color';
  static const _tagsKey = 'template_add_tags';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: 'Новый пак: ${widget.template.name}');
    _color = colorFromHex(widget.template.defaultColor);
    _selected.addAll(List.generate(widget.template.hands.length, (i) => i));
    _loadPrefs();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _color = colorFromHex(prefs.getString(_colorKey) ?? widget.template.defaultColor);
      _addTags = prefs.getBool(_tagsKey) ?? true;
    });
  }

  Future<void> _pickColor() async {
    final c = await showColorPickerDialog(context, initialColor: _color);
    if (c != null) setState(() => _color = c);
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  Future<void> _create() async {
    final service = context.read<TrainingPackStorageService>();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, colorToHex(_color));
    await prefs.setBool(_tagsKey, _addTags);
    final hands = [for (final i in _selected) widget.template.hands[i]];
    var pack = await service.createFromTemplateWithOptions(
      widget.template,
      hands: hands,
      colorTag: colorToHex(_color),
      categoryOverride: widget.template.category,
    );
    await service.renamePack(pack, _name.text.trim());
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.template.hands.length,
                itemBuilder: (_, i) {
                  final h = widget.template.hands[i];
                  return CheckboxListTile(
                    value: _selected.contains(i),
                    onChanged: (_) => _toggle(i),
                    title: Text(h.name),
                  );
                },
              ),
            ),
            Text('Выбрано: ${_selected.length} / ${widget.template.hands.length}'),
            const SizedBox(height: 16),
            Opacity(
              opacity: _selected.isNotEmpty ? 1 : 0.5,
              child: ElevatedButton(
                onPressed: _selected.isNotEmpty ? _create : null,
                child: const Text('Создать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
