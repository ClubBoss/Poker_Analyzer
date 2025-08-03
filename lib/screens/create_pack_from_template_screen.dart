import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/color_utils.dart';
import '../widgets/color_picker_dialog.dart';
import '../models/training_pack_template.dart';
import '../models/saved_hand.dart';
import '../services/training_pack_storage_service.dart';
import 'training_pack_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../utils/snackbar_util.dart';

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
  final List<SavedHand> _selected = [];
  SharedPreferences? _prefs;
  static const _colorKey = 'pack_last_color';
  static const _tagsKey = 'template_add_tags';
  static const _lastCategoryKey = 'pack_last_category';
  static const _lastPositionKey = 'pack_last_position_filter';
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _positionFilter = 'Все';
  bool _onlyWithTags = false;
  double _maxDifficulty = 3;
  bool _onlySelectedMode = false;
  bool _shuffle = false;

  double _estimateDifficulty(SavedHand hand) {
    final actions = hand.actions.length;
    if (actions > 10 || hand.numberOfPlayers > 2) return 3;
    if (actions > 5 || hand.boardStreet > 1) return 2;
    return 1;
  }

  double get _averageDifficulty {
    if (_selected.isEmpty) return 0;
    double total = 0;
    for (final h in _selected) {
      total += _estimateDifficulty(h);
    }
    return total / _selected.length;
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: 'Новый пак: ${widget.template.name}');
    _color = colorFromHex(widget.template.defaultColor);
    _selected.addAll(widget.template.hands);
    _categoryController.text = widget.template.category ?? '';
    _loadPrefs();
  }

  @override
  void dispose() {
    _name.dispose();
    _categoryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _color = colorFromHex(prefs.getString(_colorKey) ?? widget.template.defaultColor);
      _addTags = prefs.getBool(_tagsKey) ?? true;
      final cat = prefs.getString(_lastCategoryKey);
      if (cat != null && cat.isNotEmpty) _categoryController.text = cat;
      _positionFilter = prefs.getString(_lastPositionKey) ?? 'Все';
    });
  }

  Future<void> _pickColor() async {
    final c = await showColorPickerDialog(context, initialColor: _color);
    if (c != null) setState(() => _color = c);
  }

  void _toggle(SavedHand hand) {
    setState(() {
      if (_selected.contains(hand)) {
        _selected.remove(hand);
      } else {
        _selected.add(hand);
      }
    });
  }

  Future<void> _previewHand(SavedHand hand) async {
    await showSavedHandViewerDialog(context, hand);
  }

  Future<void> _editSelected() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> rename(int index) async {
            final controller =
                TextEditingController(text: _selected[index].name);
            final name = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Переименовать'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 50,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            if (name != null && name.isNotEmpty) {
              setStateDialog(() =>
                  _selected[index] = _selected[index].copyWith(name: name));
              setState(() {});
            }
          }

          void remove(int index) {
            setStateDialog(() => _selected.removeAt(index));
            setState(() {});
          }

          void reorder(int oldIndex, int newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _selected.removeAt(oldIndex);
            _selected.insert(newIndex, item);
            setStateDialog(() {});
            setState(() {});
          }

          return AlertDialog(
            title: const Text('Редактировать руки'),
            content: SizedBox(
              width: 300,
              height: 400,
              child: ReorderableListView.builder(
                onReorder: reorder,
                itemCount: _selected.length,
                itemBuilder: (context, index) {
                  final hand = _selected[index];
                  final title = hand.name.isEmpty ? 'Без названия' : hand.name;
                  return ListTile(
                    key: ValueKey(hand),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(title, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => rename(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => remove(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    if (_selected.isEmpty) {
      SnackbarUtil.showMessage(context, 'Выберите хотя бы одну раздачу перед созданием пака');
      return;
    }
    final service = context.read<TrainingPackStorageService>();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, colorToHex(_color));
    await prefs.setBool(_tagsKey, _addTags);
    await prefs.setString(_lastPositionKey, _positionFilter);
    final cat = _categoryController.text.trim();
    if (cat.isNotEmpty) await prefs.setString(_lastCategoryKey, cat);
    final hands = List<SavedHand>.from(_selected);
    if (_shuffle) hands.shuffle();
    final pack = await service.createFromTemplateWithOptions(
      widget.template,
      hands: hands,
      colorTag: colorToHex(_color),
      categoryOverride: cat.isNotEmpty ? cat : widget.template.category,
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
    final query = _searchController.text.toLowerCase();
    final filtered = <SavedHand>[
      for (final h in widget.template.hands)
        if ((_positionFilter == 'Все' || h.heroPosition == _positionFilter) &&
            (!_onlyWithTags || h.tags.isNotEmpty) &&
            _estimateDifficulty(h) <= _maxDifficulty &&
            (!_onlySelectedMode || _selected.contains(h)) &&
            (query.isEmpty || h.name.toLowerCase().contains(query)))
          h
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
      actions: [SyncStatusIcon.of(context)],
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Категория'),
            ),
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
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in ['Все', 'SB', 'BB', 'EP', 'MP', 'CO', 'BTN'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: _positionFilter == p,
                        onSelected: (s) async {
                          if (!s) return;
                          final prefs = _prefs ??
                              await SharedPreferences.getInstance();
                          await prefs.setString(_lastPositionKey, p);
                          setState(() => _positionFilter = p);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _onlyWithTags,
                  onChanged: (v) => setState(() => _onlyWithTags = v ?? false),
                ),
                const Text('Только с тегами'),
                const SizedBox(width: 12),
                const Text('Max сложность'),
                Expanded(
                  child: Slider(
                    value: _maxDifficulty,
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: _maxDifficulty.round().toString(),
                    onChanged: (v) => setState(() => _maxDifficulty = v),
                  ),
                ),
                Text(_maxDifficulty.round().toString()),
              ],
            ),
            SwitchListTile(
              title: const Text('Показывать только выбранные'),
              value: _onlySelectedMode,
              onChanged: (v) => setState(() => _onlySelectedMode = v),
            ),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Поиск по названию'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_onlySelectedMode)
                  TextButton(
                    onPressed: () => setState(() {
                      for (final h in filtered) {
                        if (!_selected.contains(h)) _selected.add(h);
                      }
                    }),
                    child: const Text('Выбрать все'),
                  ),
                TextButton(
                  onPressed: () => setState(() {
                    for (final h in filtered) {
                      _selected.remove(h);
                    }
                  }),
                  child: const Text('Снять все'),
                ),
              ],
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Нет раздач для отображения'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final h = filtered[i];
                        final title = h.name.isEmpty ? 'Без названия' : h.name;
                        return CheckboxListTile(
                          value: _selected.contains(h),
                          onChanged: (_) => _toggle(h),
                          onLongPress: () => _previewHand(h),
                          title: Text(title),
                        );
                      },
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Выбрано: ${_selected.length} / ${filtered.length}'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: _selected.isEmpty ? null : _editSelected,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Рук: ${_selected.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Сложн.: ${_averageDifficulty.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            CheckboxListTile(
              value: _shuffle,
              onChanged: (v) => setState(() => _shuffle = v ?? false),
              title: const Text('Перемешать порядок рук'),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: _selected.isNotEmpty ? 1 : 0.5,
              child: ElevatedButton(
                onPressed: _create,
                child: const Text('Создать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
