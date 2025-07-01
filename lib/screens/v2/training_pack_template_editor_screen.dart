import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/game_type.dart';
import '../../helpers/training_pack_storage.dart';
import '../../helpers/title_utils.dart';
import '../../models/v2/hand_data.dart';
import 'training_pack_spot_editor_screen.dart';
import '../../widgets/v2/training_pack_spot_preview_card.dart';
import '../../widgets/spot_viewer_dialog.dart';
import '../../services/training_session_service.dart';
import '../training_session_screen.dart';
import '../../helpers/training_pack_validator.dart';
import '../../helpers/training_pack_validator.dart';
import '../../widgets/common/ev_distribution_chart.dart';
import '../../theme/app_colors.dart';

enum SortBy { manual, title, evDesc, edited, autoEv }

TrainingPackSpot? _copiedSpot;

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final List<TrainingPackTemplate> templates;
  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    required this.templates,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() => _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState extends State<TrainingPackTemplateEditorScreen> {
  late final TextEditingController _nameCtr;
  late final FocusNode _nameFocus;
  late final TextEditingController _descCtr;
  String _query = '';
  String? _tagFilter;
  late TextEditingController _searchCtrl;
  late TextEditingController _tagSearchCtrl;
  String _tagSearch = '';
  Set<String> _selectedTags = {};
  Set<String> _selectedSpotIds = {};
  bool get _isMultiSelect => _selectedSpotIds.isNotEmpty;
  SortBy _sortBy = SortBy.manual;
  bool _autoSortEv = false;
  bool _pinnedOnly = false;
  List<TrainingPackSpot>? _lastRemoved;
  static const _prefsAutoSortKey = 'auto_sort_ev';
  static const _prefsEvFilterKey = 'ev_filter';
  String _evFilter = 'all';
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  String? _highlightId;
  final GlobalKey _previewKey = GlobalKey();

  void _focusSpot(String id) {
    final key = _itemKeys[id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      setState(() => _highlightId = id);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _highlightId == id) {
          setState(() => _highlightId = null);
        }
      });
    }
  }

  void _addSpot() async {
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      title: normalizeSpotTitle('New spot'),
    );
    setState(() => widget.template.spots.add(spot));
    TrainingPackStorage.save(widget.templates);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingPackSpotEditorScreen(spot: spot)),
    );
    setState(() {
      if (_autoSortEv) _sortSpots();
    });
    TrainingPackStorage.save(widget.templates);
  }

  Future<void> _pasteSpot() async {
    final c = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Spot'),
        content: TextField(controller: c, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (input == null || input.trim().isEmpty) return;
    try {
      final json = jsonDecode(input);
      if (json is! Map<String, dynamic>) throw const FormatException();
      final spot = TrainingPackSpot.fromJson(json)
          .copyWith(id: const Uuid().v4(), editedAt: DateTime.now());
      setState(() {
        widget.template.spots.add(spot);
        if (_autoSortEv) _sortSpots();
      });
      TrainingPackStorage.save(widget.templates);
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSpot(spot.id));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Spot pasted')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      }
    }
  }

  Future<void> _addPackTag() async {
    final allTags = widget.templates.expand((t) => t.tags).toSet().toList();
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: Autocomplete<String>(
          optionsBuilder: (v) {
            final input = v.text.toLowerCase();
            if (input.isEmpty) return allTags;
            return allTags.where((e) => e.toLowerCase().contains(input));
          },
          onSelected: (s) => Navigator.pop(context, s),
          fieldViewBuilder: (context, controller, focusNode, _) {
            controller.text = c.text;
            controller.selection = c.selection;
            controller.addListener(() {
              if (c.text != controller.text) c.value = controller.value;
            });
            c.addListener(() {
              if (controller.text != c.text) controller.value = c.value;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (tag == null || tag.isEmpty) return;
    setState(() => widget.template.tags.add(tag));
    TrainingPackStorage.save(widget.templates);
  }

  void _saveName() {
    final value = _nameCtr.text.trim();
    if (value.isEmpty) return;
    setState(() => widget.template.name = value);
    TrainingPackStorage.save(widget.templates);
  }

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.template.name);
    _nameFocus = FocusNode();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _saveName();
    });
    _descCtr = TextEditingController(text: widget.template.description);
    _searchCtrl = TextEditingController();
    _tagSearchCtrl = TextEditingController();
    SharedPreferences.getInstance().then((prefs) {
      final auto = prefs.getBool(_prefsAutoSortKey) ?? false;
      final filter = prefs.getString(_prefsEvFilterKey) ?? 'all';
      if (mounted) {
        setState(() {
          _autoSortEv = auto;
          _evFilter = filter;
          if (_autoSortEv) _sortSpots();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _nameFocus.dispose();
    _descCtr.dispose();
    _searchCtrl.dispose();
    _tagSearchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _saveName();
    if (widget.template.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    TrainingPackStorage.save(widget.templates);
    Navigator.pop(context);
  }

  Future<void> _export() async {
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safeName = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safeName.json');
      await file.writeAsString(jsonEncode(widget.template.toJson()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл сохранён: ${file.path}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось экспортировать файл')),
        );
      }
    }
  }

  Future<String?> _exportBundle({bool notify = true}) async {
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/template_bundle');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create();
      final jsonFile = File('${dir.path}/template.json');
      await jsonFile.writeAsString(jsonEncode(widget.template.toJson()));
      for (int i = 0; i < widget.template.spots.length; i++) {
        final spot = widget.template.spots[i];
        final key = _itemKeys[spot.id];
        final boundary = key?.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = data?.buffer.asUint8List();
        if (bytes == null) continue;
        final imgFile = File('${dir.path}/spot_$i.png');
        await imgFile.writeAsBytes(bytes);
      }
      final archive = Archive();
      for (final file in dir.listSync().whereType<File>()) {
        final data = await file.readAsBytes();
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile(name, data.length, data));
      }
      final bytes = ZipEncoder().encode(archive);
      if (bytes == null) throw Exception('zip');
      final downloads = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final zipFile = File('${downloads.path}/$safe.zip');
      await zipFile.writeAsBytes(bytes, flush: true);
      if (!mounted) return zipFile.path;
      if (notify) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('Bundle saved: ${zipFile.path}')),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: zipFile.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Path copied')),
                    );
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await Share.shareXFiles([XFile(zipFile.path)]);
                    } catch (_) {}
                  },
                  child: const Text('📤 Share Bundle'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(zipFile.path),
            ),
          ),
        );
      }
      return zipFile.path;
    } catch (_) {
      if (mounted && notify) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать пакет')),
        );
      }
      return null;
    }
  }

  Future<void> _shareBundle() async {
    final path = await _exportBundle(notify: false);
    if (path == null || !mounted) return;
    try {
      await Share.shareXFiles([XFile(path)]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle shared')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось поделиться пакетом')),
      );
    }
  }

  Future<void> _previewBundle() async {
    final path = await _exportBundle(notify: false);
    if (path == null || !mounted) return;
    try {
      final data = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(data);
      final files = [for (final f in archive.files) if (f.isFile) f.name];
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bundle Preview'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (_, i) => ListTile(title: Text(files[i])),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка предпросмотра пакета')),
        );
      }
    }
  }

  Future<Uint8List?> _capturePreview() async {
    final entry = OverlayEntry(
      builder: (_) => Center(
        child: Opacity(
          opacity: 0,
          child: RepaintBoundary(
            key: _previewKey,
            child: _TemplatePreviewCard(template: widget.template),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    await Future.delayed(const Duration(milliseconds: 50));
    final boundary =
        _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    Uint8List? bytes;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = data?.buffer.asUint8List();
    }
    entry.remove();
    return bytes;
  }

  Future<void> _exportPreview() async {
    final bytes = await _capturePreview();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать превью')),
        );
      }
      return;
    }
    try {
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safe.png');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text('Preview saved: ${file.path}')),
              TextButton(
                onPressed: () async {
                  try {
                    await Share.shareXFiles([XFile(file.path)]);
                  } catch (_) {}
                },
                child: const Text('📤 Share'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить превью')),
        );
      }
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'zip'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    Uint8List? data = file.bytes;
    final path = file.path;
    if (data == null && path != null) data = await File(path).readAsBytes();
    if (data == null) return;
    try {
      TrainingPackTemplate tpl;
      if (file.extension?.toLowerCase() == 'zip') {
        final tmp = await getTemporaryDirectory();
        final dir = Directory('${tmp.path}/tpl_import_${DateTime.now().microsecondsSinceEpoch}');
        if (await dir.exists()) await dir.delete(recursive: true);
        await dir.create();
        final archive = ZipDecoder().decodeBytes(data);
        for (final f in archive.files) {
          if (f.isFile && !f.name.endsWith('.png')) {
            final out = File('${dir.path}/${f.name}');
            await out.create(recursive: true);
            await out.writeAsBytes(f.content as List<int>);
          }
        }
        final tplFile = File('${dir.path}/template.json');
        final jsonStr = await tplFile.readAsString();
        final json = jsonDecode(jsonStr);
        if (json is! Map<String, dynamic>) throw const FormatException();
        tpl = TrainingPackTemplate.fromJson(json);
        await dir.delete(recursive: true);
      } else {
        final json = jsonDecode(utf8.decode(data));
        if (json is! Map<String, dynamic>) throw const FormatException();
        tpl = TrainingPackTemplate.fromJson(json);
      }
      setState(() {
        widget.template.spots
          ..clear()
          ..addAll(tpl.spots);
        if (_autoSortEv) _sortSpots();
      });
      TrainingPackStorage.save(widget.templates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Импортировано спотов: ${tpl.spots.length}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось импортировать файл')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove all spots from this template?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() => widget.template.spots.clear());
      TrainingPackStorage.save(widget.templates);
    }
  }

  void _showSummary() {
    final spots = widget.template.spots;
    final total = spots.length;
    final tags = spots.expand((s) => s.tags).toList();
    final heroEvs = [for (final s in spots) if (s.heroEv != null) s.heroEv!];
    final uniqueTags = tags.toSet();
    final counts = <String, int>{};
    for (final t in tags) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spots: $total'),
              Text('Tags: ${uniqueTags.length}'),
              const SizedBox(height: 8),
              for (final e in entries) Text('${e.key}: ${e.value}'),
              if (heroEvs.isNotEmpty) EvDistributionChart(evs: heroEvs),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _validateTemplate() {
    final issues = validateTrainingPackTemplate(widget.template);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation'),
        content: issues.isEmpty
            ? const Text('No issues found')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final e in issues) Text(e)],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkAddTag() async {
    final allTags = widget.templates.expand((t) => t.tags).toSet().toList();
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: Autocomplete<String>(
          optionsBuilder: (v) {
            final input = v.text.toLowerCase();
            if (input.isEmpty) return allTags;
            return allTags.where((e) => e.toLowerCase().contains(input));
          },
          onSelected: (s) => Navigator.pop(context, s),
          fieldViewBuilder: (context, controller, focusNode, _) {
            controller.text = c.text;
            controller.selection = c.selection;
            controller.addListener(() {
              if (c.text != controller.text) c.value = controller.value;
            });
            c.addListener(() {
              if (controller.text != c.text) controller.value = c.value;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        if (!s.tags.contains(tag)) s.tags.add(tag);
      }
    });
    await TrainingPackStorage.save(widget.templates);
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkRemoveTag() async {
    final spots = [for (final s in widget.template.spots) if (_selectedSpotIds.contains(s.id)) s];
    if (spots.isEmpty) return;
    Set<String> tags = Set.from(spots.first.tags);
    for (final s in spots.skip(1)) {
      tags = tags.intersection(s.tags.toSet());
    }
    String? selected = tags.isNotEmpty ? tags.first : null;
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Remove Tag'),
          content: DropdownButton<String>(
            value: selected,
            items: [for (final t in tags) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setStateDialog(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        s.tags.remove(tag);
      }
    });
    await TrainingPackStorage.save(widget.templates);
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkMoveToTag(String tag) async {
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        s.tags
          ..clear();
        if (tag.isNotEmpty) s.tags.add(tag);
      }
    });
    await TrainingPackStorage.save(widget.templates);
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkTogglePin() async {
    final spots = [for (final s in widget.template.spots) if (_selectedSpotIds.contains(s.id)) s];
    if (spots.isEmpty) return;
    final newState = spots.any((s) => !s.pinned);
    setState(() {
      for (final s in spots) {
        s.pinned = newState;
      }
      if (_autoSortEv) _sortSpots();
    });
    await TrainingPackStorage.save(widget.templates);
    setState(() => _selectedSpotIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newState ? 'Pinned' : 'Unpinned'} ${spots.length} spot(s)')),
    );
  }

  Future<void> _bulkTransfer(bool move) async {
    final targets = [for (final t in widget.templates) if (t.id != widget.template.id) t];
    if (targets.isEmpty) return;
    TrainingPackTemplate? selected = targets.first;
    final dest = await showDialog<TrainingPackTemplate>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(move ? 'Move to Pack' : 'Copy to Pack'),
          content: DropdownButton<TrainingPackTemplate>(
            value: selected,
            isExpanded: true,
            items: [for (final t in targets) DropdownMenuItem(value: t, child: Text(t.name))],
            onChanged: (v) => setStateDialog(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (dest == null) return;
    final spots = [for (final s in widget.template.spots) if (_selectedSpotIds.contains(s.id)) s];
    if (spots.isEmpty) return;
    final copies = [
      for (final s in spots)
        s.copyWith(
          id: const Uuid().v4(),
          editedAt: DateTime.now(),
          hand: HandData.fromJson(s.hand.toJson()),
          tags: List.from(s.tags),
        )
    ];
    setState(() {
      dest.spots.addAll(copies);
      if (move) {
        widget.template.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        if (_autoSortEv) _sortSpots();
      }
    });
    await TrainingPackStorage.save(widget.templates);
    setState(() => _selectedSpotIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${move ? 'Moved' : 'Copied'} ${copies.length} spot(s)')),
    );
  }

  Future<void> _bulkMove() => _bulkTransfer(true);
  Future<void> _bulkCopy() => _bulkTransfer(false);

  void _newPackFromSelection() {
    final spots = [
      for (final s in widget.template.spots)
        if (_selectedSpotIds.contains(s.id))
          s.copyWith(
            id: const Uuid().v4(),
            editedAt: DateTime.now(),
            hand: HandData.fromJson(s.hand.toJson()),
            tags: List.from(s.tags),
          )
    ];
    if (spots.isEmpty) return;
    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${widget.template.name} Subset',
      gameType: widget.template.gameType,
      spots: spots,
    );
    final index = widget.templates.indexOf(widget.template);
    setState(() {
      widget.templates.insert(index + 1, tpl);
      _selectedSpotIds.clear();
    });
    TrainingPackStorage.save(widget.templates);
  }

  Future<void> _bulkDelete() async {
    final count = _selectedSpotIds.length;
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $count spots?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok ?? false) {
      _lastRemoved = widget.template.spots.where((s) => _selectedSpotIds.contains(s.id)).toList();
      setState(() {
        widget.template.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        _selectedSpotIds.clear();
        if (_autoSortEv) _sortSpots();
      });
      TrainingPackStorage.save(widget.templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${_lastRemoved!.length} spot(s)'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                widget.template.spots.addAll(_lastRemoved!);
                if (_autoSortEv) _sortSpots();
              });
              TrainingPackStorage.save(widget.templates);
            },
          ),
        ),
      );
    }
  }

  void _selectAll() {
    setState(() {
      _selectedSpotIds
        ..clear()
        ..addAll(widget.template.spots.map((e) => e.id));
    });
  }

  void _invertSelection() {
    final all = widget.template.spots.map((e) => e.id).toSet();
    setState(() => _selectedSpotIds = all.difference(_selectedSpotIds));
  }

  void _duplicateSpot(TrainingPackSpot spot) {
    final i = widget.template.spots.indexOf(spot);
    if (i == -1) return;
    final copy = spot.copyWith(
      id: const Uuid().v4(),
      editedAt: DateTime.now(),
      hand: HandData.fromJson(spot.hand.toJson()),
      tags: List.from(spot.tags),
    );
    setState(() => widget.template.spots.insert(i + 1, copy));
    TrainingPackStorage.save(widget.templates);
  }

  Future<void> _renameTag() async {
    final tags = widget.template.spots.expand((s) => s.tags).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    if (tags.isEmpty) return;
    String? selected = tags.first;
    final searchCtr = TextEditingController();
    final newCtr = TextEditingController();
    final result = await showDialog<List<String>?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final filtered = tags
              .where((t) => t
                  .toLowerCase()
                  .contains(searchCtr.text.toLowerCase()))
              .toList();
          if (!filtered.contains(selected)) selected = filtered.isEmpty ? null : filtered.first;
          return AlertDialog(
            title: const Text('Rename Tag'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtr,
                  decoration: const InputDecoration(labelText: 'Search'),
                  onChanged: (_) => setStateDialog(() {}),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  items: [for (final t in filtered) DropdownMenuItem(value: t, child: Text(t))],
                  onChanged: (v) => setStateDialog(() => selected = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCtr,
                  decoration: const InputDecoration(labelText: 'New tag'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, [selected ?? '', newCtr.text.trim()]),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
    searchCtr.dispose();
    newCtr.dispose();
    if (result == null) return;
    final oldTag = result[0];
    final newTag = result[1];
    if (oldTag.isEmpty || newTag.isEmpty || oldTag == newTag) return;
    setState(() {
      for (final s in widget.template.spots) {
        if (s.tags.remove(oldTag) && !s.tags.contains(newTag)) {
          s.tags.add(newTag);
        } else {
          while (s.tags.remove(oldTag)) {}
          if (!s.tags.contains(newTag)) s.tags.add(newTag);
        }
      }
    });
    await TrainingPackStorage.save(widget.templates);
    setState(() {});
  }

  double _spotEv(TrainingPackSpot s) {
    final acts = s.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == s.hand.heroIndex) return a.ev ?? double.negativeInfinity;
    }
    return double.negativeInfinity;
  }

  void _sortSpots() {
    final pinned = widget.template.spots.where((s) => s.pinned).toList();
    final others = widget.template.spots.where((s) => !s.pinned).toList();
    others.sort((a, b) => _spotEv(b).compareTo(_spotEv(a)));
    widget.template.spots
      ..clear()
      ..addAll(pinned)
      ..addAll(others);
  }

  @override
  Widget build(BuildContext context) {
    final hasSpots = widget.template.spots.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: _isMultiSelect
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedSpotIds.clear()),
              )
            : null,
        title: _isMultiSelect
            ? Text('${_selectedSpotIds.length} selected')
            : TextField(
                controller: _nameCtr,
                focusNode: _nameFocus,
                decoration: const InputDecoration(border: InputBorder.none),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(),
              ),
        actions: [
          DropdownButton<GameType>(
            value: widget.template.gameType,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
              DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => widget.template.gameType = v);
              TrainingPackStorage.save(widget.templates);
            },
          ),
          IconButton(
            icon: Icon(Icons.push_pin, color: _pinnedOnly ? AppColors.accent : null),
            tooltip: 'Pinned Only',
            onPressed: () => setState(() => _pinnedOnly = !_pinnedOnly),
          ),
          if (_isMultiSelect)
            PopupMenuButton<String>(
              tooltip: 'Move to Tag',
              onSelected: _bulkMoveToTag,
              itemBuilder: (_) {
                final tags = widget.template.spots
                    .expand((s) => s.tags)
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.compareTo(b));
                return [
                  const PopupMenuItem(value: '', child: Text('Untagged')),
                  for (final t in tags)
                    PopupMenuItem(value: t, child: Text(t)),
                ];
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: Text('Move to Tag')),
              ),
            ),
          if (_isMultiSelect)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Selected',
              onPressed: _bulkDelete,
            ),
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (v) async {
              if (v == SortBy.autoEv) {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  _autoSortEv = !_autoSortEv;
                  if (_autoSortEv) _sortSpots();
                });
                prefs.setBool(_prefsAutoSortKey, _autoSortEv);
              } else {
                setState(() => _sortBy = v);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: SortBy.manual, child: Text('Manual')),
              const PopupMenuItem(value: SortBy.title, child: Text('Title')),
              const PopupMenuItem(value: SortBy.evDesc, child: Text('EV')),
              const PopupMenuItem(value: SortBy.edited, child: Text('Edited')),
              PopupMenuItem(
                value: SortBy.autoEv,
                child: Row(
                  children: [
                    Checkbox(value: _autoSortEv, onChanged: null),
                    const SizedBox(width: 8),
                    const Text('Auto sort by EV'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rename') _renameTag();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename Tag')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Spots',
            onPressed: _clearAll,
          ),
          IconButton(icon: const Text('📋 Paste Spot'), onPressed: _pasteSpot),
          IconButton(icon: const Icon(Icons.upload), onPressed: _import),
          IconButton(icon: const Icon(Icons.download), onPressed: _export),
          IconButton(icon: const Text('📂 Preview Bundle'), onPressed: _previewBundle),
          IconButton(icon: const Icon(Icons.archive), onPressed: () => _exportBundle()),
          IconButton(icon: const Text('📤 Share'), onPressed: _shareBundle),
          IconButton(
            icon: const Text('🖼️'),
            tooltip: 'Export PNG Preview',
            onPressed: _exportPreview,
          ),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showSummary),
          IconButton(icon: const Text('🚦 Validate'), onPressed: _validateTemplate),
          IconButton(
            onPressed: () async {
              await context
                  .read<TrainingSessionService>()
                  .startSession(widget.template, persist: false);
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingSessionScreen()),
              );
            },
            icon: const Text('▶️ Playtest'),
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _save)
        ],
      ),
      floatingActionButton: hasSpots
          ? FloatingActionButton(onPressed: _addSpot, child: const Icon(Icons.add))
          : null,
      bottomNavigationBar: hasSpots && _isMultiSelect
          ? BottomAppBar(
              child: Row(
                children: [
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('Select All'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _invertSelection,
                    child: const Text('Invert Selection'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkAddTag,
                    child: const Text('Add Tag'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkRemoveTag,
                    child: const Text('Remove Tag'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkTogglePin,
                    child: const Text('Pin / Unpin'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkMove,
                    child: const Text('Move to Pack'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _bulkCopy,
                    child: const Text('Copy to Pack'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _newPackFromSelection,
                    child: const Text('New Pack from Selection'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete'),
                    onPressed: _bulkDelete,
                  ),
                ],
              ),
            )
          : null,
      body: hasSpots
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
            TextField(
              controller: _descCtr,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onChanged: (v) {
                setState(() => widget.template.description = v);
                TrainingPackStorage.save(widget.templates);
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in widget.template.tags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() => widget.template.tags.remove(tag));
                      TrainingPackStorage.save(widget.templates);
                    },
                  ),
                InputChip(
                  label: const Text('+ Add'),
                  onPressed: _addPackTag,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GameType>(
              value: widget.template.gameType,
              decoration: const InputDecoration(labelText: 'Game Type'),
              items: const [
                DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
                DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
              ],
              onChanged: (v) {
                setState(() => widget.template.gameType = v ?? GameType.tournament);
                TrainingPackStorage.save(widget.templates);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search by title/tag',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: _tagFilter == null ? null : Colors.yellow[50],
                  filled: _tagFilter != null,
                  suffixIcon: _tagFilter != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _tagFilter = null),
                        )
                      : _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _query = '';
                                _searchCtrl.clear();
                              }),
                            ),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            Builder(
              builder: (context) {
                final allTags = widget.template.spots
                    .expand((s) => s.tags)
                    .toSet()
                    .where((t) => t
                        .toLowerCase()
                        .contains(_tagSearch.toLowerCase()))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _tagSearchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Search tags',
                        suffixIcon: _tagSearch.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() {
                                  _tagSearch = '';
                                  _tagSearchCtrl.clear();
                                }),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _tagSearch = v),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final tag in allTags)
                          FilterChip(
                            label: Text(tag),
                            selected: _selectedTags.contains(tag),
                            onSelected: (v) => setState(() {
                              v
                                  ? _selectedTags.add(tag)
                                  : _selectedTags.remove(tag);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'mistakes', label: Text('Mistakes')),
                        ButtonSegment(value: 'profitable', label: Text('Profitable')),
                      ],
                      selected: {_evFilter},
                      onSelectionChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v.first;
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Filter: Mistakes only'),
                      value: _evFilter == 'mistakes',
                      onChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v == true ? 'mistakes' : 'all';
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final shown = widget.template.spots.where((s) {
                    if (_pinnedOnly && !s.pinned) return false;
                    final ev = _spotEv(s);
                    if (_evFilter == 'mistakes' && ev >= 0) return false;
                    if (_evFilter == 'profitable' && ev < 0) return false;
                    if (_selectedTags.isNotEmpty &&
                        !s.tags.any(_selectedTags.contains)) {
                      return false;
                    }
                    if (_tagFilter != null &&
                        !s.tags.any((t) => t.toLowerCase() == _tagFilter)) {
                      return false;
                    }
                    if (_query.isEmpty) return true;
                    return s.title.toLowerCase().contains(_query) ||
                        s.tags.any((t) => t.toLowerCase().contains(_query));
                  }).toList();
                  List<TrainingPackSpot> sorted;
                  if (_sortBy == SortBy.manual) {
                    sorted = shown;
                  } else {
                    final pinned = [for (final s in shown) if (s.pinned) s];
                    final rest = [for (final s in shown) if (!s.pinned) s];
                    switch (_sortBy) {
                      case SortBy.title:
                        rest.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                        break;
                      case SortBy.evDesc:
                        double ev(TrainingPackSpot s) {
                          final acts = s.hand.actions[0] ?? [];
                          for (final a in acts) {
                            if (a.playerIndex == s.hand.heroIndex) return a.ev ?? double.negativeInfinity;
                          }
                          return double.negativeInfinity;
                        }
                        rest.sort((a, b) => ev(b).compareTo(ev(a)));
                        break;
                      case SortBy.edited:
                        rest.sort((a, b) => b.editedAt.compareTo(a.editedAt));
                        break;
                      case SortBy.autoEv:
                        break;
                      case SortBy.manual:
                        break;
                    }
                    sorted = [...pinned, ...rest];
                  }
                },
                  final groups = <String, List<TrainingPackSpot>>{};
                  for (final s in sorted) {
                    final tag = s.tags.isNotEmpty ? s.tags.first : '';
                    groups.putIfAbsent(tag, () => []).add(s);
                  }
                  final entries = groups.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));
                  return ListView.separated(
                    controller: _scrollCtrl,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, gIndex) {
                      final entry = entries[gIndex];
                      final spots = entry.value;
                      final start = sorted.indexOf(spots.first);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              entry.key.isEmpty ? 'Untagged' : entry.key,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: spots.length,
                            itemBuilder: (context, index) {
                              final spot = spots[index];
                      final selected = _selectedSpotIds.contains(spot.id);
                      final content = ReorderableDragStartListener(
                        key: ValueKey(spot.id),
                        index: index,
                        child: InkWell(
                          onTap: () async {
                            await showSpotViewerDialog(context, spot);
                            if (_autoSortEv) setState(() => _sortSpots());
                            _focusSpot(spot.id);
                          },
                          onLongPress: () => setState(() => _selectedSpotIds.add(spot.id)),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: RepaintBoundary(
                              key: _itemKeys.putIfAbsent(spot.id, () => GlobalKey()),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                color: spot.id == _highlightId ? Colors.yellow.withOpacity(0.3) : null,
                                padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isMultiSelect)
                                    Checkbox(
                                      value: selected,
                                      onChanged: (_) => setState(() {
                                        if (selected) {
                                          _selectedSpotIds.remove(spot.id);
                                        } else {
                                          _selectedSpotIds.add(spot.id);
                                        }
                                      }),
                                    ),
                                  Expanded(
                                    child: TrainingPackSpotPreviewCard(
                                      spot: spot,
                                      onHandEdited: () {
                                        setState(() {
                                          if (_autoSortEv) _sortSpots();
                                        });
                                        TrainingPackStorage.save(widget.templates);
                                      },
                                      onTagTap: (tag) => setState(() => _tagFilter = tag),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'copy') {
                                            _copiedSpot = spot.copyWith(
                                              id: const Uuid().v4(),
                                              editedAt: DateTime.now(),
                                              hand: HandData.fromJson(spot.hand.toJson()),
                                              tags: List.from(spot.tags),
                                            );
                                          } else if (v == 'paste' && _copiedSpot != null) {
                                            final i = widget.template.spots.indexOf(spot);
                                            final s = _copiedSpot!.copyWith(
                                              id: const Uuid().v4(),
                                              editedAt: DateTime.now(),
                                              hand: HandData.fromJson(_copiedSpot!.hand.toJson()),
                                              tags: List.from(_copiedSpot!.tags),
                                            );
                                            setState(() => widget.template.spots.insert(i + 1, s));
                                            TrainingPackStorage.save(widget.templates);
                                          } else if (v == 'dup') {
                                            _duplicateSpot(spot);
                                          } else if (v == 'pin') {
                                            setState(() {
                                              spot.pinned = !spot.pinned;
                                              if (_autoSortEv) _sortSpots();
                                            });
                                            TrainingPackStorage.save(widget.templates);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(value: 'pin', child: Text(spot.pinned ? '📌 Unpin' : '📌 Pin')),
                                          const PopupMenuItem(value: 'copy', child: Text('📋 Copy')),
                                          if (_copiedSpot != null) const PopupMenuItem(value: 'paste', child: Text('📥 Paste')),
                                          const PopupMenuItem(value: 'dup', child: Text('📄 Duplicate')),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => TrainingPackSpotEditorScreen(spot: spot)),
                                          );
                                          setState(() {
                                            if (_autoSortEv) _sortSpots();
                                          });
                                          TrainingPackStorage.save(widget.templates);
                                        },
                                        child: const Text('📝 Edit'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Delete spot?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (ok ?? false) {
                                            setState(() => widget.template.spots.removeAt(index));
                                            TrainingPackStorage.save(widget.templates);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                              return Dismissible(
                                key: ValueKey(spot.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.copy, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) {
                            _duplicateSpot(spot);
                          } else {
                            _lastRemoved = [spot];
                            setState(() => widget.template.spots.remove(spot));
                            TrainingPackStorage.save(widget.templates);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Deleted'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () {
                                    setState(() {
                                      widget.template.spots.addAll(_lastRemoved!);
                                      if (_autoSortEv) _sortSpots();
                                    });
                                    TrainingPackStorage.save(widget.templates);
                                  },
                                ),
                              ),
                            );
                          }
                          return false;
                        },
                                child: content,
                              );
                            },
                        onReorder: (o, n) {
                          final spot = spots[o];
                          final oldIndex = widget.template.spots.indexOf(spot);
                          final newSorted = n < spots.length ? start + n : start + spots.length;
                          final newIndex = newSorted < sorted.length
                              ? widget.template.spots.indexOf(sorted[newSorted])
                              : widget.template.spots.length;
                          setState(() {
                            final s = widget.template.spots.removeAt(oldIndex);
                            widget.template.spots.insert(
                                newIndex > oldIndex ? newIndex - 1 : newIndex, s);
                          });
                          TrainingPackStorage.save(widget.templates);
                        },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ),
            ],
          ),
        ),
      )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 96, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'This pack is empty. Tap + to add your first spot or 📋 to paste from JSON',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addSpot,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Spot'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pasteSpot,
                        icon: const Text('📋'),
                        label: const Text('Paste JSON'),
                      ),
                    ],
                  ),
                ],
              ),
            );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  final TrainingPackTemplate template;
  const _TemplatePreviewCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (template.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(template.description),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Spots: ${template.spots.length}'),
            ),
          ],
        ),
      ),
    );
  }
}
