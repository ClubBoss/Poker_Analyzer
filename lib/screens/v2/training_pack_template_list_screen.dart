import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/hand_data.dart';
import '../../models/game_type.dart';
import '../../helpers/training_pack_storage.dart';
import 'training_pack_template_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState extends State<TrainingPackTemplateListScreen> {
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = false;
  String _query = '';
  late TextEditingController _searchCtrl;
  TrainingPackTemplate? _lastRemoved;
  int _lastIndex = 0;
  GameType? _selectedType;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _loading = true;
    TrainingPackStorage.load().then((list) {
      if (!mounted) return;
      setState(() {
        _templates.addAll(list);
        _loading = false;
      });
    });
  }

  void _edit(TrainingPackTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: template,
          templates: _templates,
        ),
      ),
    );
    setState(() {});
    TrainingPackStorage.save(_templates);
  }

  Future<void> _rename(TrainingPackTemplate template) async {
    final ctrl = TextEditingController(text: template.name);
    GameType type = template.gameType;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GameType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Game Type'),
                items: const [
                  DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
                  DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
                ],
                onChanged: (v) => setState(() => type = v ?? GameType.tournament),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          template.name = name;
          template.gameType = type;
        });
        TrainingPackStorage.save(_templates);
      }
    }
  }

  void _duplicate(TrainingPackTemplate template) {
    final index = _templates.indexOf(template);
    if (index == -1) return;
    final copy = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${template.name} (copy)',
      description: template.description,
      tags: List<String>.from(template.tags),
      spots: [
        for (final s in template.spots)
          s.copyWith(
            id: const Uuid().v4(),
            hand: HandData.fromJson(s.hand.toJson()),
            tags: List<String>.from(s.tags),
          )
      ],
    );
    setState(() => _templates.insert(index + 1, copy));
    TrainingPackStorage.save(_templates);
  }

  void _add() {
    final template = TrainingPackTemplate(id: const Uuid().v4(), name: 'New Pack');
    setState(() => _templates.add(template));
    TrainingPackStorage.save(_templates);
    _edit(template);
  }

  Future<void> _export() async {
    final json = jsonEncode([for (final t in _templates) t.toJson()]);
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates copied to clipboard')),
    );
  }

  Future<void> _import() async {
    final clip = await Clipboard.getData('text/plain');
    if (clip?.text == null || clip!.text!.trim().isEmpty) return;
    List? raw;
    try {
      raw = jsonDecode(clip.text!);
    } catch (_) {}
    if (raw is! List) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      return;
    }
    final imported = [
      for (final m in raw)
        TrainingPackTemplate.fromJson(Map<String, dynamic>.from(m))
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import templates?'),
        content:
            Text('This will add ${imported.length} template(s) to your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() => _templates.addAll(imported));
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} template(s) imported')),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedType == null
        ? _templates
        : [for (final t in _templates) if (t.gameType == _selectedType) t];
    final shown = _query.isEmpty
        ? filtered
        : [
            for (final t in filtered)
              if (t.name.toLowerCase().contains(_query) ||
                  t.description.toLowerCase().contains(_query))
                t
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Packs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import',
            onPressed: _import,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _export,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search packs',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _query = '';
                              }),
                            ),
                    ),
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedType == null,
                        onSelected: (_) => setState(() => _selectedType = null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Tournament'),
                        selected: _selectedType == GameType.tournament,
                        onSelected: (_) =>
                            setState(() => _selectedType = GameType.tournament),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: _selectedType == GameType.cash,
                        onSelected: (_) =>
                            setState(() => _selectedType = GameType.cash),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: shown.length,
                    onReorder: (oldIndex, newIndex) {
                      final item = shown[oldIndex];
                      final oldPos = _templates.indexOf(item);
                      int newPos;
                      if (newIndex >= shown.length) {
                        newPos = _templates.length;
                      } else {
                        newPos = _templates.indexOf(shown[newIndex]);
                      }
                      setState(() {
                        _templates.removeAt(oldPos);
                        _templates.insert(
                          newPos > oldPos ? newPos - 1 : newPos,
                          item,
                        );
                      });
                      TrainingPackStorage.save(_templates);
                    },
                    itemBuilder: (context, index) {
                      final t = shown[index];
                      final tile = ListTile(
                        onLongPress: () => _duplicate(t),
                        title: Text(t.name),
                        subtitle: t.description.trim().isEmpty
                            ? null
                            : Text(
                                t.description.split('\n').first,
                                style: const TextStyle(fontSize: 12),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'rename') _rename(t);
                                if (v == 'duplicate') _duplicate(t);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('✏️ Rename'),
                                ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Text('📄 Duplicate'),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _edit(t),
                              child: const Text('📝 Edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _duplicate(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete pack?'),
                                    content: Text('“${t.name}” will be removed.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (ok ?? false) {
                                  final index = _templates.indexOf(t);
                                  setState(() {
                                    _lastRemoved = t;
                                    _lastIndex = index;
                                    _templates.removeAt(index);
                                  });
                                  TrainingPackStorage.save(_templates);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Deleted'),
                                      action: SnackBarAction(
                                        label: 'UNDO',
                                        onPressed: () {
                                          if (_lastRemoved != null) {
                                            setState(() => _templates.insert(_lastIndex, _lastRemoved!));
                                            TrainingPackStorage.save(_templates);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                      return Container(
                        key: ValueKey(t.id),
                        child: Row(
                          children: [
                            if (!_loading)
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            Expanded(child: tile),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
