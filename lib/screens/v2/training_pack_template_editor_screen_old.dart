part of 'training_pack_template_editor_screen.dart';

enum SortBy { manual, title, evDesc, edited, autoEv }
enum SpotSort { original, evDesc, evAsc, icmDesc, icmAsc, priorityDesc }
enum SortMode { position, chronological }

enum _RowKind { header, spot }

class _Row {
  final _RowKind kind;
  final String tag;
  final TrainingPackSpot? spot;
  const _Row.header(this.tag)
      : kind = _RowKind.header,
        spot = null;
  const _Row.spot(this.spot)
      : kind = _RowKind.spot,
        tag = '';
}

class _CatStat {
  double acc;
  double ev;
  double icm;
  _CatStat({this.acc = 0, this.ev = 0, this.icm = 0});
}

double? averageFocusCoverage(
    Map<String, int> counts, Map<String, int> totals) {
  if (counts.isEmpty) return null;
  double sum = 0;
  int n = 0;
  for (final e in counts.entries) {
    final total = totals[e.key] ?? 0;
    if (total == 0) return null;
    sum += e.value / total;
    n++;
  }
  if (n == 0) return null;
  return sum * 100 / n;
}

TrainingPackSpot? _copiedSpot;
class UndoIntent extends Intent { const UndoIntent(); }
class RedoIntent extends Intent { const RedoIntent(); }
class DeleteBulkIntent extends Intent { const DeleteBulkIntent(); }
class DuplicateBulkIntent extends Intent { const DuplicateBulkIntent(); }
class TagBulkIntent extends Intent { const TagBulkIntent(); }

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final List<TrainingPackTemplate> templates;
  final bool readOnly;
  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    required this.templates,
    this.readOnly = false,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() => _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState extends State<TrainingPackTemplateEditorScreen> with SpotListSection, TemplateSettingsSection {
  late final TextEditingController _descCtr;
  late final TextEditingController _evCtr;
  late final TextEditingController _anteCtr;
  late final TextEditingController _focusCtr;
  late final TextEditingController _handTypeCtr;
  late final FocusNode _descFocus;
  late String _templateName;
  final String _query = '';
  String? _tagFilter;
  late TextEditingController _searchCtrl;
  late TextEditingController _tagSearchCtrl;
  final String _tagSearch = '';
  final Set<String> _selectedTags = {};
  final Set<String> _selectedSpotIds = {};
  bool get _isMultiSelect => _selectedSpotIds.isNotEmpty;
  final SortBy _sortBy = SortBy.manual;
  final bool _autoSortEv = false;
  final bool _pinnedOnly = false;
  final bool _heroPushOnly = false;
  final bool _filterMistakes = false;
  final bool _filterOutdated = false;
  final bool _filterEvCovered = false;
  final bool _changedOnly = false;
  final bool _duplicatesOnly = false;
  final bool _newOnly = false;
  final bool _showMissingOnly = false;
  int? _priorityFilter;
  final FocusNode _focusNode = FocusNode();
  final bool _filtersShown = false;
  List<TrainingPackSpot>? _lastRemoved;
  static const _prefsAutoSortKey = 'auto_sort_ev';
  static const _prefsEvFilterKey = 'ev_filter';
  static const _prefsEvRangeKey = 'ev_range';
  static const _prefsTagFilterKey = 'tag_filter';
  static const _prefsQuickFilterKey = 'quick_filter';
  static const _prefsSortKey = 'sort_mode';
  static const _prefsScrollPrefix = 'template_scroll_';
  static const _prefsSortModeKey = 'templateSortMode';
  static const _prefsDupOnlyKey = 'dup_only';
  static const _prefsPinnedOnlyKey = 'pinned_only';
  static const _prefsNewOnlyKey = 'new_only';
  static const _prefsPriorityFilterKey = 'priority_filter';
  static const _prefsSortMode2Key = 'sort_mode2';
  static const _prefsPreviewModeKey = 'preview_mode';
  static const _prefsPreviewJsonPngKey = 'preview_json_png';
  static const _prefsMultiTipKey = 'multi_tip_shown';
  static String _trainedPromptKey(String tplId) => '_trainPrompt_$tplId';
  String _scrollKeyFor(TrainingPackTemplate t) => '$_prefsScrollPrefix${t.id}';
  String get _scrollKey => _scrollKeyFor(widget.template);
  final String _evFilter = 'all';
  final RangeValues _evRange = const RangeValues(-5, 5);
  final bool _evAsc = false;
  final bool _sortEvAsc = false;
  final bool _mistakeFirst = false;
  final SpotSort _spotSort = SpotSort.original;
  final SortMode _sortMode = SortMode.position;
  static const _quickFilters = [
    'BTN',
    'SB',
    'Hero push only',
    'Mistake spots',
    'High priority'
  ];
  String? _quickFilter;
  String? _positionFilter;
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _scrollDebounce;
  final Map<String, GlobalKey> _itemKeys = {};
  String? _highlightId;
  final bool _summaryIcm = false;
  final bool _evaluatingAll = false;
  final bool _generatingAll = false;
  final bool _generatingIcm = false;
  final bool _generatingExample = false;
  final bool _calculatingMissing = false;
  final double _calcProgress = 0;
  final bool _cancelRequested = false;
  final bool _exportingBundle = false;
  final bool _exportingPreview = false;
  final bool _showPasteBubble = false;
  Timer? _clipboardTimer;
  final bool _showImportIndicator = false;
  final bool _showDupHint = false;
  bool _multiTipShown = false;
  Timer? _importTimer;
  List<TrainingPackSpot>? _pasteUndo;
  late final UndoRedoService _history;
  final List<TemplateSnapshot> _snapshots = [];
  final Map<String, _CatStat> _catStats = {};
  final bool _loadingEval = false;
  double _scrollProgress = 0;
  bool _showScrollIndicator = false;
  Timer? _scrollThrottle;
  final bool _previewMode = false;
  final bool _previewJsonPng = false;
  String? _previewPath;
  TrainingPackPreset? _originPreset;
  bool get _canUndo => _history.canUndo;
  bool get _canRedo => _history.canRedo;

  void _storeTagFilter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsTagFilterKey, _tagFilter ?? '');
  }

  void _storeQuickFilter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsQuickFilterKey, _quickFilter ?? '');
  }

  void _storeSort() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortKey, _sortBy.name);
  }

  void _storePreview() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsPreviewModeKey, _previewMode);
  }

  void _storePreviewJsonPng() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsPreviewJsonPngKey, _previewJsonPng);
  }

  void _storeScroll() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = _scrollCtrl.offset;
    if (offset > 100) {
      prefs.setDouble(_scrollKey, offset);
    } else {
      prefs.remove(_scrollKey);
    }
  }

  void _updateScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final progress = max > 0 ? _scrollCtrl.position.pixels / max : 0.0;
    final show = max >= 200;
    if (progress != _scrollProgress || show != _showScrollIndicator) {
      setState(() {
        _scrollProgress = progress;
        _showScrollIndicator = show;
      });
    }
  }

  Future<void> _maybeShowMultiTip() async {
    if (_multiTipShown || _selectedSpotIds.isEmpty) return;
    _multiTipShown = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsMultiTipKey, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip: Ctrl + click to multi-select, Ctrl + D to duplicate…')),
      );
    }
  }

  void _storeDupOnly() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsDupOnlyKey, _duplicatesOnly);
  }

  void _storePinnedOnly() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsPinnedOnlyKey, _pinnedOnly);
  }

  void _storeNewOnly() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsNewOnlyKey, _newOnly);
  }

  void _storePriorityFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (_priorityFilter == null) {
      prefs.remove(_prefsPriorityFilterKey);
    } else {
      prefs.setInt(_prefsPriorityFilterKey, _priorityFilter!);
    }
  }

  void _storePriorityFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (_priorityFilter == null) {
      prefs.remove(_prefsPriorityFilterKey);
    } else {
      prefs.setInt(_prefsPriorityFilterKey, _priorityFilter!);
    }
  }

  void _storeSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortMode2Key, _sortMode.name);
  }

  Set<String> _spotHands() {
    final set = <String>{};
    for (final s in widget.template.spots) {
      final code = handCode(s.hand.heroCards);
      if (code != null) set.add(code);
    }
    return set;
  }

  Set<String> _rangeHands() {
    final range = widget.template.heroRange;
    if (range != null && range.isNotEmpty) {
      return {for (final h in range) h.toUpperCase()};
    }
    return _spotHands();
  }

  Map<String, int> _handTypeCounts() {
    final hands = _spotHands();
    final res = <String, int>{};
    for (final g in widget.template.focusHandTypes) {
      var count = 0;
      for (final code in hands) {
        if (matchHandTypeLabel(g.label, code)) count++;
      }
      res[g.label] = count;
    }
    return res;
  }

  Map<String, int> _handTypeTotals() {
    final hands = _rangeHands();
    final res = <String, int>{};
    for (final g in widget.template.focusHandTypes) {
      var count = 0;
      for (final code in hands) {
        if (matchHandTypeLabel(g.label, code)) count++;
      }
      res[g.label] = count;
    }
    return res;
  }

  }

  @override
  void initState() {
    super.initState();
    _templateName = widget.template.name;
    _descCtr = TextEditingController(text: widget.template.description);
    _evCtr = TextEditingController(
        text: widget.template.minEvForCorrect.toString());
    _anteCtr = TextEditingController(text: widget.template.anteBb.toString());
    _focusCtr = TextEditingController();
    _handTypeCtr = TextEditingController();
    _descFocus = FocusNode();
    _descFocus.addListener(() {
      if (!_descFocus.hasFocus) _saveDesc();
    });
    _searchCtrl = TextEditingController();
    _tagSearchCtrl = TextEditingController();
    _history = UndoRedoService(eventsLimit: 50);
    _history.record(widget.template.spots);
    final needs = widget.template.spots
        .any((s) => s.heroEv == null || s.heroIcmEv == null);
    if (needs) {
      setState(() => _loadingEval = true);
      BulkEvaluatorService()
          .generateMissing(widget.template, onProgress: null)
          .then((_) {
        TemplateCoverageUtils.recountAll(widget.template);
        if (mounted) setState(() => _loadingEval = false);
      });
    }
    _scrollCtrl.addListener(() {
      if (_scrollThrottle?.isActive ?? false) return;
      _scrollThrottle =
          Timer(const Duration(milliseconds: 100), _updateScroll);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScroll();
      _maybeStartTraining();
      _loadCategoryStats();
    });
    _clipboardTimer ??=
        Timer.periodic(const Duration(seconds: 2), (_) => _checkClipboard());
    _checkClipboard();
    SharedPreferences.getInstance().then((prefs) {
      final auto = prefs.getBool(_prefsAutoSortKey) ?? false;
      final filter = prefs.getString(_prefsEvFilterKey) ?? 'all';
      final rangeStr = prefs.getString(_prefsEvRangeKey);
      final tag = prefs.getString(_prefsTagFilterKey);
      final quick = prefs.getString(_prefsQuickFilterKey);
      final sortStr = prefs.getString(_prefsSortKey);
      final sortMode = prefs.getString(_prefsSortModeKey);
      final mode2 = prefs.getString(_prefsSortMode2Key);
      final offset = prefs.getDouble(_scrollKey) ?? 0;
      final dupOnly = prefs.getBool(_prefsDupOnlyKey) ?? false;
      final pinnedOnly = prefs.getBool(_prefsPinnedOnlyKey) ?? false;
      final newOnly = prefs.getBool(_prefsNewOnlyKey) ?? false;
      final priorityFilter = prefs.getInt(_prefsPriorityFilterKey);
      final preview = prefs.getBool(_prefsPreviewModeKey) ?? false;
      final png = prefs.getBool(_prefsPreviewJsonPngKey) ?? false;
      final multiTip = prefs.getBool(_prefsMultiTipKey) ?? false;
      final snapsRaw = prefs.getString('tpl_snapshots_${widget.template.id}');
      var range = const RangeValues(-5, 5);
      if (rangeStr != null) {
        final parts = rangeStr.split(',');
        if (parts.length == 2) {
          final start = double.tryParse(parts[0]);
          final end = double.tryParse(parts[1]);
          if (start != null && end != null) {
            range = RangeValues(start, end);
          }
        }
      }
      List<TemplateSnapshot> snaps = [];
      if (snapsRaw != null) {
        try {
          final list = jsonDecode(snapsRaw) as List;
          snaps = [
            for (final s in list)
              TemplateSnapshot.fromJson(Map<String, dynamic>.from(s as Map))
          ];
        } catch (_) {}
      }
      SortBy sort = SortBy.manual;
      if (sortStr != null) {
        for (final v in SortBy.values) {
          if (v.name == sortStr) {
            sort = v;
            break;
          }
        }
      }
      if (sortMode != null) _evAsc = sortMode == 'asc';
      if (mounted) {
        setState(() {
          _autoSortEv = auto;
          _evFilter = filter;
          _evRange = range;
          _tagFilter = tag?.isEmpty ?? true ? null : tag;
          _quickFilter = quick?.isEmpty ?? true ? null : quick;
          _sortBy = sort;
          _duplicatesOnly = dupOnly;
          _pinnedOnly = pinnedOnly;
          _newOnly = newOnly;
          _priorityFilter = priorityFilter;
          _snapshots = snaps;
          _previewMode = preview;
          _previewJsonPng = png;
          _multiTipShown = multiTip;
          _loadPreview();
          if (widget.readOnly) _previewMode = true;
      if (mode2 != null) {
            for (final v in SortMode.values) {
              if (v.name == mode2) _sortMode = v;
            }
          }
          if (sortMode != null) _sortSpots();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            final max = _scrollCtrl.position.maxScrollExtent;
            _scrollCtrl.jumpTo(min(offset, max));
            _updateScroll();
          }
        });
        _ensureEval();
      }
    });
    TrainingPackPresetRepository.getAll().then((list) {
      final p = list.firstWhereOrNull((e) => e.id == widget.template.id);
      if (p != null && mounted) setState(() => _originPreset = p);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filtersShown && MediaQuery.of(context).size.width < 400) {
      _filtersShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _storeScroll();
    _descFocus.dispose();
    _descCtr.dispose();
    _evCtr.dispose();
    _anteCtr.dispose();
    _focusCtr.dispose();
    _handTypeCtr.dispose();
    _searchCtrl.dispose();
    _tagSearchCtrl.dispose();
    _scrollThrottle?.cancel();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _clipboardTimer?.cancel();
    _importTimer?.cancel();
    super.dispose();
  }

  void _save() {
    _saveDesc();
    if (widget.template.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final ready = validateTrainingPackTemplate(widget.template).isEmpty;
    widget.template.isDraft = !ready;
    TemplateCoverageUtils.recountAll(widget.template);
    TrainingPackStorage.save(widget.templates);
    unawaited(
      BulkEvaluatorService()
          .generateMissing(widget.template, onProgress: null)
          .then((_) {
        final ctx = navigatorKey.currentState?.context;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('EV/ICM updated'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }),
    );
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
    if (_exportingBundle) return null;
    setState(() => _exportingBundle = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/template_bundle');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create();
      final jsonFile = File('${dir.path}/template.json');
      await jsonFile.writeAsString(jsonEncode(widget.template.toJson()));
      for (int i = 0; i < widget.template.spots.length; i++) {
        final spot = widget.template.spots[i];
        final preview = TrainingPackSpotPreviewCard(spot: spot);
        final label = spot.title.isNotEmpty ? spot.title : 'Spot ${i + 1}';
        final bytes = await PngExporter.exportSpot(preview, label: label);
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
    } finally {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) setState(() => _exportingBundle = false);
    }
  }

  Future<void> _shareBundle() async {
    if (!mounted) return;
    await PackExportService.exportBundle(widget.template);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bundle shared')));
  }

  Future<void> _exportPackBundle() async {
    if (_exportingBundle) return;
    setState(() => _exportingBundle = true);
    try {
      final file = await PackExportService.exportBundle(widget.template);
      if (!mounted) return;
      await FileSaverService.instance.saveZip(file.path);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bundle exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingBundle = false);
    }
  }

  Future<void> _exportCsv() async {
    try {
      if (!mounted) return;
      await PackExportService.exportToCsv(widget.template);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CSV exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
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

  Future<Uint8List?> _capturePreview() {
    return PngExporter.exportWidget(
      _TemplatePreviewCard(template: widget.template),
    );
  }

  Future<void> _exportPreview() async {
    if (_exportingPreview) return;
    setState(() => _exportingPreview = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await _capturePreview();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Не удалось создать превью')));
        }
        return;
      }
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Не удалось сохранить превью')));
      }
    } finally {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) setState(() => _exportingPreview = false);
    }
  }

  Future<void> _exportPreviewJson() async {
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    var pngName = name;
    if (_previewJsonPng) {
      final c = TextEditingController(text: pngName);
      final res = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PNG name'),
          content: TextField(controller: c, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
          ],
        ),
      );
      if (res != null && res.isNotEmpty) pngName = res;
    }
    try {
      await FileSaverService.instance.saveJson(name, widget.template.toJson());
      if (_previewJsonPng) {
        final bytes = await _capturePreview();
        if (bytes != null) {
          await FileSaverService.instance.savePng(pngName, bytes);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _exportPreviewSummary() async {
    final spots = widget.template.spots;
    final total = spots.length;
    final evCovered = spots.where((s) => s.heroEv != null && !s.dirty).length;
    final icmCovered =
        spots.where((s) => s.heroIcmEv != null && !s.dirty).length;
    final data = {
      'id': widget.template.id,
      'name': widget.template.name,
      'spotCount': total,
      'evCoverage': total == 0 ? 0.0 : evCovered / total,
      'icmCoverage': total == 0 ? 0.0 : icmCovered / total,
    };
    final safe =
        widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_summary_$safe';
    try {
      await FileSaverService.instance.saveJson(name, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  String _generatePreviewMarkdown() {
    final spots = widget.template.spots;
    final total = spots.length;
    final evCovered = spots.where((s) => s.heroEv != null && !s.dirty).length;
    final icmCovered =
        spots.where((s) => s.heroIcmEv != null && !s.dirty).length;
    final buffer = StringBuffer()
      ..writeln('# ${widget.template.name}')
      ..writeln('- **ID:** ${widget.template.id}')
      ..writeln('- **Spots:** $total')
      ..writeln(
          '- **EV coverage:** ${total == 0 ? 0 : (evCovered / total * 100).toStringAsFixed(1)}%')
      ..writeln(
          '- **ICM coverage:** ${total == 0 ? 0 : (icmCovered / total * 100).toStringAsFixed(1)}%')
      ..writeln(
          '- **Created:** ${DateFormat('yyyy-MM-dd').format(widget.template.createdAt)}');
    final tags = widget.template.tags.toSet().where((e) => e.isNotEmpty).toList();
    if (tags.isNotEmpty) buffer.writeln('- **Tags:** ${tags.join(', ')}');
    return buffer.toString().trimRight();
  }

  Future<void> _exportPreviewMarkdown([String? md]) async {
    md ??= _generatePreviewMarkdown();
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    try {
      await FileSaverService.instance.saveMd(name, md);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Markdown saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _previewMarkdown() async {
    final md = _generatePreviewMarkdown();
    final ok = await showMarkdownPreviewDialog(context, md);
    if (ok == true) await _exportPreviewMarkdown(md);
  }

  void _showMarkdownPreview() {
    showDialog(
      context: context,
      builder: (_) => MarkdownPreviewDialog(template: widget.template),
    );
  }

  Future<void> _exportPreviewCsv() async {
    final rows = <List<dynamic>>[
      ['Position', 'HeroCards', 'Board', 'EV', 'Tags']
    ];
    for (final s in widget.template.spots) {
      final h = s.hand;
      rows.add([
        h.position.name,
        h.heroCards,
        h.board.join(' '),
        s.heroEv?.toStringAsFixed(2) ?? '',
        s.tags.join('|'),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    try {
      await FileSaverService.instance.saveCsv(name, csvStr);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('CSV saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _exportPreviewZip() async {
    final archive = Archive();
    final jsonData = utf8.encode(jsonEncode(widget.template.toJson()));
    archive.addFile(ArchiveFile('template.json', jsonData.length, jsonData));
    final dir = await TrainingPackStorage.previewImageDir(widget.template);
    if (await dir.exists()) {
      for (final file in dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.png'))) {
        final bytes = await file.readAsBytes();
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }
    final bytes = ZipEncoder().encode(archive);
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    try {
      await FileSaverService.instance.saveZip(name, Uint8List.fromList(bytes));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ZIP saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _sharePreviewZip() async {
    final archive = Archive();
    final jsonData = utf8.encode(jsonEncode(widget.template.toJson()));
    archive.addFile(ArchiveFile('template.json', jsonData.length, jsonData));
    final dir = await TrainingPackStorage.previewImageDir(widget.template);
    if (await dir.exists()) {
      for (final file
          in dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.png'))) {
        final bytes = await file.readAsBytes();
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }
    await Future.delayed(Duration.zero);
    final bytes = ZipEncoder().encode(archive);
    final tmp = await getTemporaryDirectory();
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(
        '${tmp.path}/preview_${safe}_${DateTime.now().millisecondsSinceEpoch}.zip');
    await file.writeAsBytes(bytes, flush: true);
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {}
    if (await file.exists()) await file.delete();
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
    _recordSnapshot();
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
      _persist();
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
      _recordSnapshot();
      setState(() => widget.template.spots.clear());
      _persist();
      setState(() => _history.log('Deleted', 'all spots', ''));
    }
  }

  Future<void> _clearTags() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear tags for all spots?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok ?? false) {
      _recordSnapshot();
      setState(() {
        for (final s in widget.template.spots) {
          s.tags.clear();
        }
      });
      await _persist();
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

  Future<void> _validateAllSpots() async {
    final issues = <SpotIssue>[];
    var progress = 0.0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final spots = widget.template.spots;
                for (var i = 0; i < spots.length; i++) {
                  issues.addAll(validateSpot(spots[i], i));
                  progress = (i + 1) / spots.length;
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 1));
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (issues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All spots valid'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in issues)
                  ListTile(
                    title: Text(i.message),
                    onTap: () {
                      Navigator.pop(context);
                      _focusSpot(i.spotId);
                    },
                  ),
              ],
            ),
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



  void _regenerateEv() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
              a.ev = computePushEV(
                heroBbStack: stack,
                bbCount: spot.hand.playerCount - 1,
                heroHand: hand,
              anteBb: widget.template.anteBb,
              );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _regenerateIcm() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
              final chipEv = a.ev ?? computePushEV(
                heroBbStack: stack,
                bbCount: spot.hand.playerCount - 1,
                heroHand: hand,
              anteBb: widget.template.anteBb,
              );
            a.icmEv = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: chipEv,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _recalculateAll() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
              a.ev = computePushEV(
                heroBbStack: stack,
                bbCount: spot.hand.playerCount - 1,
                heroHand: hand,
              anteBb: widget.template.anteBb,
              );
              a.icmEv = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: a.ev!,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  Future<void> _reEvaluateAll() async {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            final ev = computePushEV(
              heroBbStack: stack,
              bbCount: spot.hand.playerCount - 1,
              heroHand: hand,
              anteBb: widget.template.anteBb,
            );
            final icm = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: ev,
            );
            a
              ..ev = ev
              ..icmEv = icm;
            final r = spot.evalResult;
            spot.evalResult = EvaluationResult(
              correct: r?.correct ?? true,
              expectedAction: r?.expectedAction ?? 'push',
              userEquity: r?.userEquity ?? 0,
              expectedEquity: r?.expectedEquity ?? 0,
              ev: ev,
              icmEv: icm,
              hint: r?.hint,
            );
            spot.dirty = false;
            break;
          }
        }
      }
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Re-evaluated ${widget.template.spots.length} spots')),
    );
  }

  void _tagAllMistakes() {
    int count = 0;
    setState(() {
      for (final s in widget.template.spots) {
        final r = s.evalResult;
        if (r != null && !r.correct && !s.tags.contains('Mistake')) {
          s.tags.add('Mistake');
          _history.log('Tagged', s.title, s.id);
          count++;
        }
      }
    });
    _persist();
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tagged $count spot(s)')),
      );
    }
  }

  Future<void> _evaluateAllSpots() async {
    setState(() => _evaluatingAll = true);
    final spots = widget.template.spots;
    final total = spots.length;
    int done = 0;
    int errors = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (final spot in spots) {
                  try {
                    final res = await context
                        .read<EvaluationExecutorService>()
                        .evaluate(spot);
                    if (mounted) {
                      setState(() => spot.evalResult = res);
                      await _persist();
                    }
                  } catch (e) {
                    errors++;
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Spot "${spot.title}" failed: $e'),
                        ),
                      );
                    }
                  }
                  done++;
                  if (mounted) setDialog(() {});
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: done / total),
                  const SizedBox(height: 12),
                  Text(
                    'Evaluated $done / $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _evaluatingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Evaluated $total spots (${total - errors} OK, $errors errors)'),
      ),
    );
  }

  Future<void> _generateAllEv() async {
    setState(() => _generatingAll = true);
    final spots = _visibleSpots();
    final total = spots.length;
    int done = 0;
    final failed = <String>[];
    _cancelRequested = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < spots.length; i++) {
                  if (_cancelRequested) break;
                  final s = spots[i];
                  try {
                    if (s.heroEv == null) {
                      await const PushFoldEvService()
                          .evaluate(s, anteBb: widget.template.anteBb);
                      TemplateCoverageUtils.recountAll(widget.template);
                      if (!mounted) return;
                      setState(() {
                        if (_autoSortEv) _sortSpots();
                      });
                    }
                    if (mounted) setState(() {});
                  } catch (_) {
                    failed.add('${i + 1}. ${s.title.isEmpty ? 'Spot' : s.title}');
                  }
                  done++;
                  if (mounted) setDialog(() {});
                  await Future.delayed(Duration.zero);
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total EV…'),
              actions: [
                TextButton(
                  onPressed: () => _cancelRequested = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _generatingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generated $total spots (${total - failed.length} OK, ${failed.length} errors)'),
      ),
    );
    if (failed.isNotEmpty) {
      await _showGenerationErrors(failed, 'EV');
    }
  }

  Future<void> _generateAllIcm() async {
    setState(() => _generatingIcm = true);
    final spots = _visibleSpots();
    final total = spots.length;
    int done = 0;
    final failed = <String>[];
    _cancelRequested = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < spots.length; i++) {
                  if (_cancelRequested) break;
                  final s = spots[i];
                  try {
                    if (s.heroIcmEv == null) {
                      await const PushFoldEvService()
                          .evaluateIcm(s, anteBb: widget.template.anteBb);
                      TemplateCoverageUtils.recountAll(widget.template);
                      if (!mounted) return;
                      setState(() {
                        if (_autoSortEv) _sortSpots();
                      });
                    }
                    if (mounted) setState(() {});
                  } catch (_) {
                    failed.add('${i + 1}. ${s.title.isEmpty ? 'Spot' : s.title}');
                  }
                  done++;
                  if (mounted) setDialog(() {});
                  await Future.delayed(Duration.zero);
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total ICM…'),
              actions: [
                TextButton(
                  onPressed: () => _cancelRequested = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _generatingIcm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generated $total spots (${total - failed.length} OK, ${failed.length} errors)'),
      ),
    );
    if (failed.isNotEmpty) {
      await _showGenerationErrors(failed, 'ICM');
    }
  }

  Future<void> _showGenerationErrors(List<String> failed, String type) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$type Generation Errors (${failed.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: failed.length,
            itemBuilder: (_, i) => ListTile(title: Text(failed[i])),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: failed.join('\n')));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadPreview() async {
    final png = widget.template.png;
    if (png != null) {
      final path = await PreviewCacheService.instance.getPreviewPath(png);
      if (mounted) setState(() => _previewPath = path);
    }
  }

  Future<void> _ensureEval() async {
    final needs = widget.template.spots.any((s) =>
        s.heroEv == null || s.heroIcmEv == null || s.dirty);
    if (!needs) return;
    setState(() => _loadingEval = true);
    await BulkEvaluatorService()
        .generateMissingForTemplate(widget.template, onProgress: null)
        .catchError((_) {});
    TemplateCoverageUtils.recountAll(widget.template);
    if (mounted) setState(() => _loadingEval = false);
  }

  void _maybeStartTraining() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_trainedPromptKey(widget.template.id)) ?? false) return;
    final hasPush =
        widget.template.spots.any((s) => s.tags.contains('push'));
    final hasFold =
        widget.template.spots.any((s) => s.tags.contains('fold'));
    if (!(hasPush && hasFold)) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(l.startTrainingSessionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          )
        ],
      ),
    );
    prefs.setBool(_trainedPromptKey(widget.template.id), true);
    if (ok != true || !mounted) return;
    await context
        .read<TrainingSessionService>()
        .startSession(widget.template, persist: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
    if (!mounted) return;
  }

  Future<void> _calculateMissingEvIcm() async {
    setState(() {
      _calculatingMissing = true;
      _calcProgress = 0;
    });
    int updated = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final res = await BulkEvaluatorService().generateMissing(
                  widget.template,
                  onProgress: (p) {
                    _calcProgress = p;
                    if (mounted) {
                      setDialog(() {});
                      setState(() {});
                    }
                  },
                );
                updated = res.length;
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: _calcProgress),
                  const SizedBox(height: 12),
                  Text(
                    '${(_calcProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _calculatingMissing = false);
    if (updated > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Updated $updated spots')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to update')));
    }
  }

  Future<void> _loadCategoryStats() async {
    if (widget.template.lastTrainedAt == null) {
      setState(() => _catStats.clear());
      return;
    }
    final accMap = await TrainingPackStatsService.getCategoryStats();
    final hands = context.read<SavedHandManagerService>().hands;
    final cats = <String>{};
    for (final s in widget.template.spots) {
      for (final t in s.tags.where((t) => t.startsWith('cat:'))) {
        cats.add(t.substring(4));
      }
    }
    final map = <String, _CatStat>{};
    for (final c in cats) {
      double evSum = 0;
      int evCount = 0;
      double icmSum = 0;
      int icmCount = 0;
      for (final h in hands.where((h) => h.category == c)) {
        final ev = h.heroEv;
        if (ev != null) {
          evSum += ev;
          evCount++;
        }
        final icm = h.heroIcmEv;
        if (icm != null) {
          icmSum += icm;
          icmCount++;
        }
      }
      final acc = accMap[c];
      if (acc != null || evCount > 0 || icmCount > 0) {
        map[c] = _CatStat(
          acc: acc ?? 0,
          ev: evCount > 0 ? evSum / evCount : 0,
          icm: icmCount > 0 ? icmSum / icmCount : 0,
        );
      }
    }
    if (mounted) setState(() => _catStats = map);
  }

  Future<void> _bulkAddTag([List<String>? ids]) async {
    final service = context.read<TemplateStorageService>();
    final allTags = {
      ...service.templates.expand((t) => t.tags),
      ...widget.template.tags,
    }.toList();
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
    final targets = ids ?? _selectedSpotIds.toList();
    if (targets.isEmpty) return;
    _recordSnapshot();
    setState(() {
      for (final id in targets) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        if (!s.tags.contains(tag)) {
          s.tags.add(tag);
          _history.log('Tagged', s.title, s.id);
        }
        s.isNew = false;
      }
      if (ids == null) _selectedSpotIds.clear();
    });
    await _persist();
    if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
      setState(() => _newOnly = false);
      _storeNewOnly();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tagged ${targets.length} spot(s)'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final snap = _history.undo(widget.template.spots);
            if (snap != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(snap);
                if (_autoSortEv) _sortSpots();
              });
              await _persist();
            }
          },
        ),
      ),
    );
  }

  Future<void> _bulkTag() => _bulkAddTag();

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
        if (s.tags.remove(tag)) {
          _history.log('Untagged', s.title, s.id);
        }
      }
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkMoveToTag(String tag) async {
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        s.tags
          .clear();
        if (tag.isNotEmpty) {
          s.tags.add(tag);
          _history.log('Tagged', s.title, s.id);
        } else {
          _history.log('Untagged', s.title, s.id);
        }
      }
    });
    await _persist();
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
    await _persist();
    setState(() {
      _selectedSpotIds.clear();
      if (!newState) {
        _pinnedOnly = false;
        _storePinnedOnly();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newState ? 'Pinned' : 'Unpinned'} ${spots.length} spot(s)')),
    );
  }

  Future<void> _bulkTransfer(bool move, [List<String>? ids]) async {
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
    final spots = [
      for (final s in widget.template.spots)
        if ((ids ?? _selectedSpotIds).contains(s.id)) s
    ];
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
      for (final s in spots) {
        s.isNew = false;
      }
    });
    await _persist();
    if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
      setState(() => _newOnly = false);
      _storeNewOnly();
    }
    if (ids == null) setState(() => _selectedSpotIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${move ? 'Moved' : 'Copied'} ${copies.length} spot(s)')),
    );
  }

  Future<void> _bulkMove() => _bulkTransfer(true);
  Future<void> _bulkCopy() => _bulkTransfer(false);
  Future<void> _bulkDuplicate() async {
    final spots = [
      for (final s in widget.template.spots)
        if (_selectedSpotIds.contains(s.id)) s
    ];
    if (spots.isEmpty) return;
    _recordSnapshot();
    setState(() {
      for (final spot in spots) {
        final i = widget.template.spots.indexOf(spot);
        final copy = spot.copyWith(
          id: const Uuid().v4(),
          editedAt: DateTime.now(),
          hand: HandData.fromJson(spot.hand.toJson()),
          tags: List.from(spot.tags),
        );
        widget.template.spots.insert(i + 1, copy);
      }
      if (_autoSortEv) _sortSpots();
      _selectedSpotIds.clear();
    });
    await _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicated ${spots.length} spot(s)'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final snap = _history.undo(widget.template.spots);
            if (snap != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(snap);
                if (_autoSortEv) _sortSpots();
              });
              await _persist();
            }
          },
        ),
      ),
    );
  }

  Future<void> _recalcSelected() async {
    final spots = [
      for (final s in widget.template.spots)
        if (_selectedSpotIds.contains(s.id)) s
    ];
    if (spots.isEmpty) return;
    setState(() {
      _calculatingMissing = true;
      _calcProgress = 0;
    });
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                var done = 0;
                for (final spot in spots) {
                  await BulkEvaluatorService().generateMissing(
                    spot,
                    anteBb: widget.template.anteBb,
                  );
                  done++;
                  _calcProgress = done / spots.length;
                  if (mounted) {
                    setDialog(() {});
                    setState(() {});
                  }
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: _calcProgress),
                  const SizedBox(height: 12),
                  Text(
                    '${(_calcProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _calculatingMissing = false;
      _selectedSpotIds.clear();
      if (_autoSortEv) _sortSpots();
    });
  }

  Future<void> _newPackFromSelection() async {
    final ctrl = TextEditingController(text: '${widget.template.name} Subset');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Pack'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, ctrl.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
    if (name == null) return;
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
      name: name.isEmpty ? 'New Pack' : name,
      gameType: widget.template.gameType,
      spots: spots,
      createdAt: DateTime.now(),
    );
    final service = context.read<TemplateStorageService>();
    service.addTemplate(tpl);
    final index = widget.templates.indexOf(widget.template);
    setState(() {
      widget.templates.insert(index + 1, tpl);
      _selectedSpotIds.clear();
    });
    await _persist();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: tpl,
          templates: widget.templates,
        ),
      ),
    );
  }

  Future<void> _bulkExport() async {
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
    _recordSnapshot();
    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name:
          '${widget.template.name} – Export ${DateFormat.yMd().format(DateTime.now())}',
      gameType: widget.template.gameType,
      spots: spots,
      createdAt: DateTime.now(),
    );
    final service = context.read<TemplateStorageService>();
    service.addTemplate(tpl);
    final index = widget.templates.indexOf(widget.template);
    setState(() {
      widget.templates.insert(index + 1, tpl);
      _selectedSpotIds.clear();
    });
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${spots.length} spot(s)'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              service.removeTemplate(tpl);
              setState(() => widget.templates.remove(tpl));
              await _persist();
            },
          ),
        ),
      );
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: tpl,
          templates: widget.templates,
        ),
      ),
    );
  }

  Future<void> _makeMistakePack() async {
    final mistakes = widget.template.spots
        .where((s) => s.tags.contains('Mistake'))
        .map((s) => s.copyWith(id: const Uuid().v4()))
        .toList();
    if (mistakes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No mistakes found')));
      return;
    }
    final newTpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${widget.template.name} – Mistakes',
      gameType: widget.template.gameType,
      spots: mistakes,
      createdAt: DateTime.now(),
    );
    final service = context.read<TemplateStorageService>();
    service.addTemplate(newTpl);
    widget.templates.add(newTpl);
    await TrainingPackStorage.save(widget.templates);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: newTpl,
          templates: widget.templates,
        ),
      ),
    );
  }


  Future<void> _startTrainingSession() async {
    await context
        .read<TrainingSessionService>()
        .startSession(widget.template, persist: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Future<void> _addToLibrary() async {
    final list = await TrainingPackStorage.load();
    list.add(widget.template);
    await TrainingPackStorage.save(list);
    context.read<TemplateStorageService>().addTemplate(widget.template);
    if (mounted) Navigator.pop(context);
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
      _recordSnapshot();
      _lastRemoved = widget.template.spots.where((s) => _selectedSpotIds.contains(s.id)).toList();
      for (final s in _lastRemoved!) {
        s.isNew = false;
      }
      setState(() {
        widget.template.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        _selectedSpotIds.clear();
        if (_autoSortEv) _sortSpots();
      });
      _persist();
      if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
        setState(() => _newOnly = false);
        _storeNewOnly();
      }
      setState(() =>
          _history.log('Deleted', '${_lastRemoved!.length} spots', ''));
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
              _persist();
            },
          ),
        ),
      );
    }
  }

  Future<void> _bulkDeleteQuick() async {
    final ids = _selectedSpotIds.toSet();
    if (ids.isEmpty) return;
    _recordSnapshot();
    setState(() {
      widget.template.spots.removeWhere((s) => ids.contains(s.id));
      _selectedSpotIds.clear();
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${ids.length} spot(s)'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final snap = _history.undo(widget.template.spots);
            if (snap != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(snap);
                if (_autoSortEv) _sortSpots();
              });
              await _persist();
            }
          },
        ),
      ),
    );
  }

  void _toggleSelectAll() {
    final allIds = {for (final s in widget.template.spots) s.id};
    setState(() {
      if (_selectedSpotIds.length == allIds.length) {
        _selectedSpotIds.clear();
      } else {
        _selectedSpotIds
          ..clear()
          ..addAll(allIds);
      }
    });
    _maybeShowMultiTip();
  }

  void _selectAllNew() {
    setState(() {
      _selectedSpotIds
        ..clear()
        ..addAll([
          for (final s in widget.template.spots)
            if (s.isNew) s.id
        ]);
    });
    _maybeShowMultiTip();
  }

  void _selectAllDuplicates() {
    final dups = _duplicateSpotGroups().expand((g) => g.skip(1));
    setState(() {
      _selectedSpotIds
        ..clear()
        ..addAll([for (final i in dups) widget.template.spots[i].id]);
    });
    _maybeShowMultiTip();
  }

  void _invertSelection() {
    final all = widget.template.spots.map((e) => e.id).toSet();
    setState(() => _selectedSpotIds = all.difference(_selectedSpotIds));
    _maybeShowMultiTip();
  }

  bool _onKey(FocusNode _, RawKeyEvent e) {
    if (e is! RawKeyDownEvent) return false;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyP && e.isAltPressed) {
      setState(() {
        _pinnedOnly = !_pinnedOnly;
        _storePinnedOnly();
      });
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyN && e.isAltPressed) {
      setState(() {
        _newOnly = !_newOnly;
        _storeNewOnly();
      });
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyD && e.isAltPressed) {
      setState(() {
        _duplicatesOnly = !_duplicatesOnly;
        _storeDupOnly();
      });
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyS && e.isAltPressed) {
      _toggleSortMode();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyV && e.isAltPressed) {
      _importFromClipboardSpots();
      return true;
    }
    final isCmd = e.isControlPressed || e.isMetaPressed;
    if (!isCmd) return false;
    if (e.logicalKey == LogicalKeyboardKey.keyA) {
      _toggleSelectAll();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyI) {
      _invertSelection();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyS && e.isShiftPressed) {
      _selectAllDuplicates();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyD && e.isShiftPressed) {
      setState(() => _showDupHint = false);
      _findDuplicateSpots();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyV) {
      _validateAllSpots();
      return true;
    }
    return false;
  }

  PreferredSizeWidget _bulkBar() {
    final n = _selectedSpotIds.length;
    if (n == 0) return const SizedBox.shrink();
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.grey[900],
      title: Text('$n selected'),
      actions: const [
        IconButton(icon: Icon(Icons.delete), tooltip: 'Delete', onPressed: _bulkDeleteQuick),
        IconButton(icon: Icon(Icons.copy_all), tooltip: 'Duplicate', onPressed: _bulkDuplicate),
        IconButton(icon: Icon(Icons.label), tooltip: 'Tag', onPressed: _bulkTag),
        IconButton(icon: Icon(Icons.open_in_new), tooltip: 'Export to Pack', onPressed: _bulkExport),
      ],
    );
  }

  void _duplicateSpot(TrainingPackSpot spot) {
    _recordSnapshot();
    final i = widget.template.spots.indexOf(spot);
    if (i == -1) return;
    final copy = spot.copyWith(
      id: const Uuid().v4(),
      editedAt: DateTime.now(),
      hand: HandData.fromJson(spot.hand.toJson()),
      tags: List.from(spot.tags),
    );
    setState(() => widget.template.spots.insert(i + 1, copy));
    _persist();
    setState(() => _log('Added', copy));
  }

  /// Универсальное меню для карточки спота
  Widget _buildSpotMenu(TrainingPackSpot spot) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (v) {
        switch (v) {
          case 'pin':
            setState(() {
              spot.pinned = !spot.pinned;
              if (_autoSortEv) _sortSpots();
            });
            _persist();
            break;
          case 'copy':
            _copiedSpot = spot.copyWith(
              id: const Uuid().v4(),
              editedAt: DateTime.now(),
              hand: HandData.fromJson(spot.hand.toJson()),
              tags: List.from(spot.tags),
            );
            break;
          case 'paste':
            if (_copiedSpot != null) {
              final i = widget.template.spots.indexOf(spot);
              final s = _copiedSpot!.copyWith(
                id: const Uuid().v4(),
                editedAt: DateTime.now(),
                hand: HandData.fromJson(_copiedSpot!.hand.toJson()),
                tags: List.from(_copiedSpot!.tags),
              );
              setState(() => widget.template.spots.insert(i + 1, s));
              _persist();
            }
            break;
          case 'dup':
            _duplicateSpot(spot);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pin',
          child: Text(spot.pinned ? '📌 Unpin' : '📌 Pin'),
        ),
        const PopupMenuItem(value: 'copy',  child: Text('📋 Copy')),
        if (_copiedSpot != null)
          const PopupMenuItem(value: 'paste', child: Text('📥 Paste')),
        const PopupMenuItem(value: 'dup',   child: Text('📄 Duplicate')),
      ],
    );
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
    await _persist();
    setState(() {});
  }

  Future<void> _manageTags() async {
    final tags = <String>{
      ...widget.template.tags,
      ...widget.template.spots.expand((s) => s.tags),
    }.toList()
      ..sort((a, b) => a.compareTo(b));
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          void rename(String oldTag, String newTag) {
            if (newTag.isEmpty || oldTag == newTag) return;
            setState(() {
              for (final s in widget.template.spots) {
                for (var i = 0; i < s.tags.length; i++) {
                  if (s.tags[i] == oldTag) s.tags[i] = newTag;
                }
                s.tags = s.tags.toSet().toList();
              }
              widget.template.tags.removeWhere((t) => t == oldTag);
              if (!widget.template.tags.contains(newTag)) {
                widget.template.tags.add(newTag);
              }
            });
            _persist();
            setStateDialog(() {
              final i = tags.indexOf(oldTag);
              if (i != -1) tags[i] = newTag;
            });
          }

          void remove(String tag) {
            setState(() {
              widget.template.tags.removeWhere((t) => t == tag);
              for (final s in widget.template.spots) {
                s.tags.removeWhere((t) => t == tag);
              }
            });
            _persist();
            setStateDialog(() => tags.remove(tag));
          }

          return AlertDialog(
            title: const Text('Manage Tags'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tag in tags)
                    _ManageTagTile(
                      key: ValueKey(tag),
                      tag: tag,
                      onRename: (v) => rename(tag, v),
                      onDelete: () => remove(tag),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }


  List<List<int>> _duplicateSpotGroups() =>
      duplicateSpotGroupsStatic(widget.template.spots);

  bool _isDup(TrainingPackSpot s) {
    final index = widget.template.spots.indexOf(s);
    if (index == -1) return false;
    for (final g in _duplicateSpotGroups()) {
      if (g.skip(1).contains(index)) return true;
    }
    return false;
  }

  bool _importDuplicateGroups(List<TrainingPackSpot> imported) {
    final before = _pasteUndo ?? [];
    final existing = <String>{};
    for (final s in before) {
      final h = s.hand;
      final hero = h.heroCards.replaceAll(' ', '');
      final board = h.board.join();
      existing.add('${h.position.name}-$hero-$board');
    }
    for (final s in imported) {
      final h = s.hand;
      final hero = h.heroCards.replaceAll(' ', '');
      final board = h.board.join();
      final key = '${h.position.name}-$hero-$board';
      if (existing.contains(key)) return true;
      existing.add('$key-${s.editedAt.millisecondsSinceEpoch}-${s.id}');
    }
    return false;
  }

  String _duplicateSpotTitle(int i) {
    final h = widget.template.spots[i].hand;
    final hero = h.heroCards;
    final board = h.board.join(' ');
    return '${h.position.label} $hero – $board';
  }

  void _deleteDuplicateSpotGroups(List<List<int>> groups) {
    _recordSnapshot();
    final removed = <(TrainingPackSpot, int)>[];
    for (final g in groups) {
      for (final i in g) {
        widget.template.spots[i].isNew = false;
      }
    }
    setState(() {
      for (final g in groups) {
        for (final i in g.skip(1).toList().reversed) {
          final s = widget.template.spots.removeAt(i);
          removed.add((s, i));
        }
      }
      if (_autoSortEv) _sortSpots();
      _showDupHint = false;
    });
    if (_duplicatesOnly) _duplicatesOnly = false;
    _persist();
    setState(() => _selectedSpotIds.clear());
    setState(() => _history.log('Deleted', '${removed.length} spots', ''));
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${removed.length} spots'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in removed.reversed) {
                widget.template.spots.insert(
                    r.$2.clamp(0, widget.template.spots.length), r.$1);
              }
              if (_autoSortEv) _sortSpots();
            });
            _persist();
          },
        ),
      ),
    );
  }

  void _mergeDuplicateSpotGroups(List<List<int>> groups) {
    _recordSnapshot();
    final removed = <(TrainingPackSpot, int)>[];
    for (final g in groups) {
      for (final i in g) {
        widget.template.spots[i].isNew = false;
      }
    }
    setState(() {
      for (final g in groups) {
        final baseIndex = g.first;
        var base = widget.template.spots[baseIndex];
        final tags = {...base.tags};
        String note = base.note;
        bool pinned = base.pinned;
        for (final i in g.skip(1)) {
          final s = widget.template.spots[i];
          tags.addAll(s.tags);
          if (s.note.isNotEmpty) {
            if (note.isNotEmpty) note += '\n';
            note += s.note;
          }
          if (s.pinned) pinned = true;
          removed.add((s, i));
        }
        base = base.copyWith(tags: tags.toList(), note: note, pinned: pinned);
        widget.template.spots[baseIndex] = base;
        for (final i in g.skip(1).toList().reversed) {
          widget.template.spots.removeAt(i);
        }
      }
      if (_autoSortEv) _sortSpots();
      _showDupHint = false;
    });
    if (_duplicatesOnly) _duplicatesOnly = false;
    _persist();
    setState(() => _selectedSpotIds.clear());
    setState(() => _history.log('Deleted', '${removed.length} spots', ''));
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Merged ${removed.length} spots'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in removed.reversed) {
                widget.template.spots.insert(
                    r.$2.clamp(0, widget.template.spots.length), r.$1);
              }
              if (_autoSortEv) _sortSpots();
            });
            _persist();
          },
        ),
      ),
    );
  }

  Future<void> _findDuplicateSpots() async {
    final groups = _duplicateSpotGroups();
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No duplicates')));
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Duplicates (${groups.length})',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final g in groups)
                ListTile(
                  title: Text(
                    _duplicateSpotTitle(g.first),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    g.map((i) => widget.template.spots[i].title).join(', '),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'delete') {
      _deleteDuplicateSpotGroups(groups);
    } else if (result == 'merge') {
      _mergeDuplicateSpotGroups(groups);
    }
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
    if (_evAsc) {
      others.sort((a, b) => _spotEv(a).compareTo(_spotEv(b)));
    } else {
      others.sort((a, b) => _spotEv(b).compareTo(_spotEv(a)));
    }
    widget.template.spots
      ..clear()
      ..addAll(pinned)
      ..addAll(others);
  }

  Future<void> _toggleEvSort() async {
    setState(() {
      _evAsc = !_evAsc;
      _sortSpots();
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortModeKey, _evAsc ? 'asc' : 'desc');
  }

  void _toggleSortMode() {
    setState(() {
      _sortMode = _sortMode == SortMode.chronological
          ? SortMode.position
          : SortMode.chronological;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _sortMode == SortMode.position
              ? 'Sorted by position'
              : 'Sorted by date added',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _storeSortMode();
  }

  void _showFilters() {
    final tags = widget.template.spots.expand((s) => s.tags).toSet();
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Pinned Only'),
                value: _pinnedOnly,
                onChanged: (v) => set(() {
                  this.setState(() => _pinnedOnly = v);
                  _storePinnedOnly();
                }),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in tags)
                    FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (v) => set(() {
                        this.setState(() {
                          v ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                        });
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _evFilter,
                decoration: const InputDecoration(labelText: 'EV'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'ok', child: Text('OK')),
                  DropdownMenuItem(value: 'error', child: Text('Errors')),
                  DropdownMenuItem(value: 'empty', child: Text('Empty')),
                ],
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  final val = v ?? 'all';
                  set(() => _evFilter = val);
                  this.setState(() {});
                  prefs.setString(_prefsEvFilterKey, val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _priorityFilter,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (int i = 1; i <= 5; i++)
                    DropdownMenuItem(value: i, child: Text('$i')),
                ],
                onChanged: (v) async {
                  set(() => _priorityFilter = v);
                  this.setState(() {});
                  _storePriorityFilter();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTemplateSettings() async {
    final heroCtr = TextEditingController(text: widget.template.heroBbStack.toString());
    final stacks = [
      for (var i = 0; i < 9; i++)
        if (i < widget.template.playerStacksBb.length)
          widget.template.playerStacksBb[i]
        else
          0
    ];
    final stackCtrs = [
      for (var i = 0; i < 9; i++)
        TextEditingController(text: stacks[i].toString())
    ];
    HeroPosition pos = widget.template.heroPos;
    final countCtr = TextEditingController(text: widget.template.spotCount.toString());
    double bbCall = widget.template.bbCallPct.toDouble();
    final anteCtr = TextEditingController(text: widget.template.anteBb.toString());
    String rangeStr = widget.template.heroRange?.join(' ') ?? '';
    String rangeMode = 'simple';
    final rangeCtr = TextEditingController(text: rangeStr);
    bool rangeErr = false;
    final eval = EvaluationSettingsService.instance;
    final thresholdCtr =
        TextEditingController(text: eval.evThreshold.toStringAsFixed(2));
    final endpointCtr = TextEditingController(text: eval.remoteEndpoint);
    bool icm = eval.useIcm;
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, set) {
            final narrow = MediaQuery.of(context).size.width < 500;
            final fields = [
                TextFormField(
                  controller: heroCtr,
                  decoration: const InputDecoration(labelText: 'Hero BB Stack'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? '≥ 1' : null,
                ),
              DropdownButtonFormField<HeroPosition>(
                value: pos,
                decoration: const InputDecoration(labelText: 'Hero Position'),
                items: const [
                  DropdownMenuItem(value: HeroPosition.sb, child: Text('SB')),
                  DropdownMenuItem(value: HeroPosition.bb, child: Text('BB')),
                  DropdownMenuItem(value: HeroPosition.btn, child: Text('BTN')),
                  DropdownMenuItem(value: HeroPosition.co, child: Text('CO')),
                  DropdownMenuItem(value: HeroPosition.mp, child: Text('MP')),
                  DropdownMenuItem(value: HeroPosition.utg, child: Text('UTG')),
                ],
                onChanged: (v) => set(() => pos = v ?? HeroPosition.sb),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Player Stacks (BB)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < stackCtrs.length; i++)
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: stackCtrs[i],
                            decoration: InputDecoration(labelText: '#$i'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (int.tryParse(v ?? '') ?? -1) < 0 ? '≥ 0' : null,
                            onChanged: (v) async {
                              final val = int.tryParse(v) ?? 0;
                              set(() {
                                while (widget.template.playerStacksBb.length <
                                    stackCtrs.length) {
                                  widget.template.playerStacksBb.add(0);
                                }
                                widget.template.playerStacksBb[i] = val;
                              });
                              await _persist();
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              TextFormField(
                controller: countCtr,
                decoration: const InputDecoration(labelText: 'Spot Count'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? 0;
                  return n < 1 || n > 169 ? '' : null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BB call ${bbCall.round()}%'),
                  Slider(
                    value: bbCall,
                    min: 0,
                    max: 100,
                    onChanged: (v) => set(() => bbCall = v),
                  ),
                ],
              ),
              TextFormField(
                controller: anteCtr,
                decoration: const InputDecoration(labelText: 'Ante (BB)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? -1;
                  return n < 0 || n > 5 ? '' : null;
                },
              ),
              TextFormField(
                controller: thresholdCtr,
                decoration: const InputDecoration(labelText: 'EV Threshold'),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                onChanged: (v) => set(() {
                  final val = double.tryParse(v) ?? eval.evThreshold;
                  eval.update(threshold: val);
                  this.setState(() {});
                }),
              ),
              SwitchListTile(
                title: const Text('ICM mode'),
                value: icm,
                onChanged: (v) => set(() {
                  icm = v;
                  eval.update(icm: v);
                  this.setState(() {});
                }),
              ),
              TextFormField(
                controller: endpointCtr,
                decoration:
                    const InputDecoration(labelText: 'EV API Endpoint'),
                onChanged: (v) => set(() {
                  eval.update(endpoint: v);
                  this.setState(() {});
                }),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: rangeMode,
                    items: const [
                      DropdownMenuItem(value: 'simple', child: Text('Simple')),
                      DropdownMenuItem(value: 'matrix', child: Text('Matrix')),
                    ],
                    onChanged: (v) => set(() => rangeMode = v ?? 'simple'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: rangeMode == 'simple'
                        ? TextFormField(
                            controller: rangeCtr,
                            decoration: InputDecoration(
                              labelText: 'Hero Range',
                              errorText: rangeErr ? '' : null,
                            ),
                            onChanged: (v) => set(() {
                              rangeStr = v;
                              rangeErr = v.trim().isNotEmpty &&
                                  PackGeneratorService.parseRangeString(v).isEmpty;
                            }),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final init = PackGeneratorService
                                  .parseRangeString(rangeStr)
                                  .toSet();
                              final res = await Navigator.push<Set<String>>(
                                context,
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => MatrixPickerPage(initial: init),
                                ),
                              );
                              if (res != null) {
                                set(() {
                                rangeStr = PackGeneratorService.serializeRange(res);
                                rangeCtr.text = rangeStr;
                                rangeErr = rangeStr.trim().isNotEmpty &&
                                    PackGeneratorService.parseRangeString(rangeStr).isEmpty;
                              });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hero Range',
                                errorText: rangeErr ? '' : null,
                              ),
                              child: Text(
                                rangeStr.isEmpty ? 'All hands' : rangeStr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('PNG with JSON'),
                value: _previewJsonPng,
                onChanged: (v) => set(() {
                  this.setState(() => _previewJsonPng = v);
                  _storePreviewJsonPng();
                }),
              ),
            ];
            final content = narrow
                ? Column(mainAxisSize: MainAxisSize.min, children: fields)
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [for (final f in fields) SizedBox(width: 250, child: f)],
                  );
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fix errors')));
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (ok == true) {
      final hero = int.parse(heroCtr.text.trim());
      final list = [
        for (final c in stackCtrs)
          int.tryParse(c.text.trim()) ?? 0
      ];
      final count = int.parse(countCtr.text.trim());
      int ante = int.parse(anteCtr.text.trim());
      if (ante < 0) ante = 0;
      if (ante > 5) ante = 5;
      final parsedSet = PackGeneratorService.parseRangeString(rangeStr);
      setState(() {
        widget.template.heroBbStack = hero;
        widget.template.playerStacksBb = list;
        widget.template.heroPos = pos;
        widget.template.spotCount = count;
        widget.template.bbCallPct = bbCall.round();
        widget.template.anteBb = ante;
        widget.template.heroRange =
            parsedSet.isEmpty ? null : parsedSet.toList();
      });
      _markAllDirty();
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Template settings updated')));
      }
    }
    heroCtr.dispose();
    for (final c in stackCtrs) {
      c.dispose();
    }
    countCtr.dispose();
    anteCtr.dispose();
    rangeCtr.dispose();
    thresholdCtr.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEval) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final narrow = MediaQuery.of(context).size.width < 400;
    final hasSpots = widget.template.spots.isNotEmpty;
    final variants = widget.template.playableVariants();
    final showExample = !hasSpots && variants.length == 1;
    const posLabels = ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'];
    final shown = _visibleSpots();
    final chipVals = [for (final s in shown) if (s.heroEv != null) s.heroEv!];
    final icmVals = [for (final s in shown) if (s.heroIcmEv != null) s.heroIcmEv!];
    final total = widget.template.spots.length;
    final evTotal = total == 0 ? 0.0 : widget.template.evCovered / total;
    final icmTotal = total == 0 ? 0.0 : widget.template.icmCovered / total;
    final primaryColor = Theme.of(context).primaryColor;
    final totalSpots = shown.length;
    final mistakeCount =
        widget.template.spots.where((s) => s.tags.contains('Mistake')).length;
    final mistakeFree =
        shown.where((s) => !s.tags.contains('Mistake')).length;
    final mistakePct = totalSpots == 0 ? 0 : mistakeFree / totalSpots;
    final evCovered = shown.where((s) => s.heroEv != null && !s.dirty).length;
    final icmCovered = shown.where((s) => s.heroIcmEv != null && !s.dirty).length;
    final evCoverage = totalSpots == 0 ? 0.0 : evCovered / totalSpots;
    final icmCoverage = totalSpots == 0 ? 0.0 : icmCovered / totalSpots;
    final coverageWarningNeeded = evCoverage < 0.8 || icmCoverage < 0.8;
    final bothCoverage = evCoverage < icmCoverage ? evCoverage : icmCoverage;
    final heroEvsAll = [
      for (final s in shown)
        if (s.heroEv != null && !s.dirty) s.heroEv!
    ];
    final inLibrary = context
        .watch<TemplateStorageService>()
        .templates
        .any((t) => t.id == widget.template.id);
    final canAddToLibrary = _originPreset != null && !inLibrary;
    final avgEv = heroEvsAll.isEmpty
        ? null
        : heroEvsAll.reduce((a, b) => a + b) / heroEvsAll.length;
    final mistakesVisible =
        shown.where((s) => s.tags.contains('Mistake')).length;
    final tagCounts = <String, int>{};
    for (final t in shown.expand((s) => s.tags)) {
      tagCounts[t] = (tagCounts[t] ?? 0) + 1;
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summaryTags = [for (final e in topTags.take(3)) e.key];
    final handCounts = _handTypeCounts();
    final handTotals = _handTypeTotals();
    final focusAvg = averageFocusCoverage(handCounts, handTotals);
    final historyGroups = <String, List<ChangeEntry>>{};
    for (final e in _history.history) {
      final day = DateFormat.yMd().format(e.time);
      historyGroups.putIfAbsent(day, () => []).add(e);
    }
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
    if (_spotSort != SpotSort.original) {
      final pinned = [for (final s in sorted) if (s.pinned) s];
      final rest = [for (final s in sorted) if (!s.pinned) s];
      int Function(TrainingPackSpot, TrainingPackSpot) cmp;
      switch (_spotSort) {
        case SpotSort.evDesc:
          cmp = (a, b) =>
              (b.heroEv ?? double.negativeInfinity).compareTo(a.heroEv ?? double.negativeInfinity);
          break;
        case SpotSort.evAsc:
          cmp = (a, b) =>
              (a.heroEv ?? double.infinity).compareTo(b.heroEv ?? double.infinity);
          break;
        case SpotSort.icmDesc:
          cmp = (a, b) => (b.heroIcmEv ?? double.negativeInfinity)
              .compareTo(a.heroIcmEv ?? double.negativeInfinity);
          break;
        case SpotSort.icmAsc:
          cmp = (a, b) =>
              (a.heroIcmEv ?? double.infinity).compareTo(b.heroIcmEv ?? double.infinity);
          break;
        case SpotSort.priorityDesc:
          cmp = (a, b) => b.priority.compareTo(a.priority);
          break;
        default:
          cmp = (a, b) => 0;
      }
      rest.sort(cmp);
      sorted = [...pinned, ...rest];
    }
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const DeleteBulkIntent(),
        LogicalKeySet(LogicalKeyboardKey.backspace): const DeleteBulkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): const DuplicateBulkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT): const TagBulkIntent(),
      },
      child: Actions(
        actions: {
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _undo()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => _redo()),
          DeleteBulkIntent: CallbackAction(onInvoke: (_) => _selectedSpotIds.isEmpty ? null : _bulkDeleteQuick()),
          DuplicateBulkIntent: CallbackAction(onInvoke: (_) => _selectedSpotIds.isEmpty ? null : _bulkDuplicate()),
          TagBulkIntent: CallbackAction(onInvoke: (_) => _selectedSpotIds.isEmpty ? null : _bulkTag()),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          onKey: (n, e) => _onKey(n, e)
              ? KeyEventResult.handled
              : KeyEventResult.ignored,
          child: Scaffold(

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + (_isMultiSelect ? kToolbarHeight : 0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isMultiSelect) _bulkBar(),
            AppBar(
        leading: _isMultiSelect
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedSpotIds.clear()),
              )
            : null,
        title: _isMultiSelect
            ? Text('${_selectedSpotIds.length} selected')
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.readOnly)
                              Text(_templateName)
                            else
                              GestureDetector(
                                onTap: _renameTemplate,
                                child: Text(_templateName),
                              ),
                            const SizedBox(width: 8),
                            Builder(builder: (_) {
                              final int evPct = (evCoverage * 100).round();
                              final int icmPct = (icmCoverage * 100).round();
                              Color colorFor(int p) {
                                if (p < 70) return Colors.red;
                                if (p < 90) return Colors.amber;
                                return Colors.green;
                              }
                              return Row(
                                children: [
                                  Chip(
                                    label: Text('EV $evPct%',
                                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: colorFor(evPct),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text('ICM $icmPct%',
                                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: colorFor(icmPct),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        Builder(builder: (context) {
                          final total = widget.template.spots.length;
                          final ev = widget.template.evCovered;
                          final icm = widget.template.icmCovered;
                          final evPct = total == 0 ? 0 : (ev * 100 / total).round();
                          final icmPct = total == 0 ? 0 : (icm * 100 / total).round();
                          Color avgColor(double v) {
                            if (v >= 0.5) return Colors.green;
                            if (v <= -0.5) return Colors.red;
                            return Colors.yellow;
                          }
                          return Row(
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: '$evPct% EV',
                                  children: [
                                    const TextSpan(text: ' • '),
                                    TextSpan(text: '$icmPct% ICM'),
                                  ],
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              if (avgEv != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${avgEv >= 0 ? '+' : ''}${avgEv.toStringAsFixed(2)} BB',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: avgColor(avgEv)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('Mistakes $mistakesVisible/${shown.length}',
                                    style: const TextStyle(fontSize: 12, color: Colors.white)),
                                backgroundColor: mistakesVisible > 0
                                    ? Colors.redAccent
                                    : Colors.grey,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  Builder(builder: (_) {
                    final missing =
                        BulkEvaluatorService().countMissing(widget.template);
                    return Row(
                      children: [
                        Text(
                          '${_visibleSpotsCount()} spots',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$missing missing',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Missing only'),
                          selected: _showMissingOnly,
                          onSelected: (_) =>
                              setState(() => _showMissingOnly = !_showMissingOnly),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Mistakes'),
                          selected: _filterMistakes,
                          onSelected: (_) =>
                              setState(() => _filterMistakes = !_filterMistakes),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Mistakes ↑'),
                          selected: _mistakeFirst,
                          onSelected: (_) =>
                              setState(() => _mistakeFirst = !_mistakeFirst),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(_sortEvAsc ? 'Manual ↺' : 'Sort EV ↑'),
                          selected: _sortEvAsc,
                          onSelected: (_) =>
                              setState(() => _sortEvAsc = !_sortEvAsc),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int?>(
                          value: _priorityFilter,
                          hint: const Text('Priority', style: TextStyle(color: Colors.white70)),
                          dropdownColor: AppColors.cardBackground,
                          style: const TextStyle(color: Colors.white),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All')),
                            for (int i = 1; i <= 5; i++)
                              DropdownMenuItem(value: i, child: Text('$i')),
                          ],
                          onChanged: (v) {
                            setState(() => _priorityFilter = v);
                            _storePriorityFilter();
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
        actions: widget.readOnly
            ? [
                const IconButton(
                    onPressed: _startTrainingSession,
                    icon: Text('Start Training')),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
              ]
            : [
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
              _persist();
            },
          ),
          IconButton(icon: const Text('↶'), onPressed: _canUndo ? _undo : null),
          IconButton(icon: const Text('↷'), onPressed: _canRedo ? _redo : null),
          const IconButton(
            icon: Text('🔄'),
            tooltip: 'Jump to last change',
            onPressed: _jumpToLastChange,
          ),
          const IconButton(
            icon: Icon(Icons.bookmark_add),
            tooltip: 'Save Snapshot',
            onPressed: _saveSnapshotAction,
          ),
          const IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Snapshots',
            onPressed: _showSnapshots,
          ),
          if (_showPasteBubble &&
              widget.template.spots.any((s) => s.isNew))
            const TextButton(onPressed: _undoImport, child: Text('Undo Import')),
          IconButton(
            icon: Icon(_evAsc ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: 'Sort by EV',
            onPressed: _toggleEvSort,
          ),
          IconButton(
            icon: Icon(Icons.sort,
                color:
                    _sortMode == SortMode.chronological ? AppColors.accent : null),
            tooltip: 'Sort Mode',
            onPressed: _toggleSortMode,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Quick Filter',
            onSelected: (v) {
              setState(() => _quickFilter = _quickFilter == v ? null : v);
              _storeQuickFilter();
            },
            itemBuilder: (_) => [
              for (final f in _quickFilters)
                CheckedPopupMenuItem(value: f, checked: _quickFilter == f, child: Text(f)),
            ],
          ),
          if (widget.template.spots.any((s) => !s.isNew && _isDup(s)))
            const TextButton(
              onPressed: _selectAllDuplicates,
              child: Text('Select Duplicates'),
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
            const IconButton(
              icon: Icon(Icons.copy_all),
              tooltip: 'New Pack',
              onPressed: _newPackFromSelection,
            ),
          if (_isMultiSelect)
            const IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete (Ctrl + Backspace)',
              onPressed: _bulkDelete,
            ),
          if (_isMultiSelect)
            const IconButton(
              icon: Icon(Icons.auto_fix_high),
              tooltip: 'Recalc EV/ICM',
              onPressed: _recalcSelected,
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
                _storeSort();
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
          const IconButton(
            icon: Text('🏷️'),
            tooltip: 'Manage Tags',
            onPressed: _manageTags,
          ),
          const IconButton(
            icon: Text('🧹'),
            tooltip: 'Clear Tags',
            onPressed: _clearTags,
          ),
          const IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Clear All Spots',
            onPressed: _clearAll,
          ),
          const IconButton(icon: Text('📋 Paste Spot'), onPressed: _pasteSpot),
          const IconButton(icon: Text('📥 Paste Hand'), onPressed: _pasteHandHistory),
          const IconButton(icon: Icon(Icons.upload), onPressed: _import),
          const IconButton(icon: Icon(Icons.download), onPressed: _export),
          Badge.count(
            count: mistakeCount,
            isLabelVisible: mistakeCount > 0,
            child: IconButton(
              icon: const Text('📂 Preview Bundle'),
              onPressed: _exportingBundle ? null : _previewBundle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _exportingBundle ? null : _exportPackBundle,
          ),
          IconButton(
            icon: const Text('📤 Share'),
            onPressed: _exportingBundle ? null : _shareBundle,
          ),
          IconButton(
            icon: const Text('🖼️'),
            tooltip: 'Export PNG Preview',
            onPressed: _exportingPreview ? null : _exportPreview,
          ),
          const IconButton(icon: Icon(Icons.info_outline), onPressed: _showSummary),
          const IconButton(icon: Text('🚦 Validate'), onPressed: _validateTemplate),
          const IconButton(icon: Text('✅ All'), tooltip: 'Validate All', onPressed: _validateAllSpots),
          IconButton(
            icon: Icon(Icons.push_pin, color: _pinnedOnly ? AppColors.accent : null),
            tooltip: 'Pinned Only',
            onPressed: () {
              setState(() => _pinnedOnly = !_pinnedOnly);
              _storePinnedOnly();
            },
          ),
          IconButton(
            icon: Icon(Icons.fiber_new, color: _newOnly ? AppColors.accent : null),
            tooltip: 'New Only',
            onPressed: () {
              setState(() => _newOnly = !_newOnly);
              _storeNewOnly();
            },
          ),
          IconButton(
            icon: Icon(Icons.error_outline,
                color: _quickFilter == 'Mistake spots' ? AppColors.accent : null),
            tooltip: 'Mistakes Only',
            onPressed: () {
              setState(() => _quickFilter = _quickFilter == 'Mistake spots'
                  ? null
                  : 'Mistake spots');
              _storeQuickFilter();
            },
          ),
          const IconButton(
            icon: Icon(Icons.copy_all),
            tooltip: 'Find Duplicates',
            onPressed: _findDuplicateSpots,
          ),
          IconButton(
            icon: Icon(Icons.copy_all,
                color: _duplicatesOnly ? AppColors.accent : null),
            tooltip: 'Duplicates Only',
            onPressed: () {
              setState(() => _duplicatesOnly = !_duplicatesOnly);
              _storeDupOnly();
            },
          ),
          const IconButton(icon: Text('⚙️ Settings'), onPressed: _showTemplateSettings),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'regenEv') _regenerateEv();
              if (v == 'regenIcm') _regenerateIcm();
              if (v == 'reEval') _reEvaluateAll();
              if (v == 'exportCsv') _exportCsv();
              if (v == 'tagMistakes') _tagAllMistakes();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, set) => SwitchListTile(
                    title: const Text('Offline Mode'),
                    value: OfflineEvaluatorService.isOffline,
                    onChanged: (v) => set(() => OfflineEvaluatorService.isOffline = v),
                  ),
                ),
              ),
              const PopupMenuItem(value: 'regenEv', child: Text('Regenerate EV')),
              const PopupMenuItem(value: 'regenIcm', child: Text('Regenerate ICM')),
              const PopupMenuItem(value: 'reEval', child: Text('Re-evaluate All')),
              const PopupMenuItem(value: 'exportCsv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'tagMistakes', child: Text('Tag All Mistakes')),
            ],
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: IconButton(
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
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: IconButton(
              icon: Icon(
                  _previewMode ? Icons.edit : Icons.remove_red_eye_outlined),
              tooltip: 'Preview Mode',
              onPressed: () {
                setState(() => _previewMode = !_previewMode);
                _storePreview();
              },
          ),
        ),
        const IconButton(
          icon: Icon(Icons.bug_report),
          tooltip: 'Make Mistake Pack',
          onPressed: _makeMistakePack,
        ),
        const IconButton(icon: Icon(Icons.save), onPressed: _save),
        const IconButton(icon: Icon(Icons.description), onPressed: _showMarkdownPreview),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                if (!mounted) return;
                await PackExportService.exportToPdf(widget.template);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('PDF exported')));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
          ),
          const IconButton(
              onPressed: _startTrainingSession,
              icon: Text('Start Training'))
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🟡 New, 🔵 Edited', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: const Icon(Icons.search),
                    fillColor: _tagFilter == null ? null : Colors.yellow[50],
                filled: _tagFilter != null,
                suffixIcon: _tagFilter != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _tagFilter = null);
                          _storeTagFilter();
                        },
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in posLabels) ...[
                        FilterChip(
                          label: Text(label),
                          selected: _positionFilter == label,
                          onSelected: (_) => setState(() => _positionFilter = _positionFilter == label ? null : label),
                        ),
                        const SizedBox(width: 8),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : hasSpots && !_isMultiSelect
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showPasteBubble) ...[
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'tmplPasteBubble',
                        mini: true,
                        onPressed: _importFromClipboardSpots,
                        label: Text('Paste Hands'),
                      ),
                      SizedBox(width: 8),
                  IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: _clearClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (_showDupHint) ...[
                  FloatingActionButton.extended(
                    heroTag: 'dupHint',
                    mini: true,
                    backgroundColor: Colors.amber,
                    onPressed: () {
                      setState(() => _showDupHint = false);
                      _findDuplicateSpots();
                    },
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Duplicates found'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (narrow)
                  const FloatingActionButton(
                    heroTag: 'filterSpotFab',
                    onPressed: _showFilters,
                    child: Icon(Icons.filter_list),
                  ),
                if (narrow) const SizedBox(height: 12),
                const FloatingActionButton(
                  heroTag: 'addSpotFab',
                  onPressed: _addSpot,
                  child: Icon(Icons.add),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'newSpotFab',
                  onPressed: _newSpot,
                  icon: Icon(Icons.add),
                  label: Text('+ New Spot'),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'quickSpotFab',
                  onPressed: _quickSpot,
                  icon: Icon(Icons.flash_on),
                  label: Text('+ Quick Spot'),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton(
                  heroTag: 'generateSpotFab',
                  tooltip: 'Generate Spot',
                  onPressed: _generateSpot,
                  child: Icon(Icons.auto_fix_high),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'generateSpotsFab',
                  icon: Icon(Icons.auto_fix_high),
                  label: Text('Generate Spots'),
                  onPressed: _generateSpots,
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'generateMissingFab',
                  icon: Icon(Icons.playlist_add),
                  label: Text('Generate Missing'),
                  onPressed: _generateMissingSpots,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'evalAllSpotsFab',
                  icon: _evaluatingAll
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_play),
                  label: const Text('Evaluate All'),
                  onPressed: _evaluatingAll ? null : _evaluateAllSpots,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'calcMissingFab',
                  icon: _calculatingMissing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate),
                  label: const Text('Calculate Missing EV/ICM'),
                  onPressed:
                      _calculatingMissing ? null : _calculateMissingEvIcm,
                ),
                if (canAddToLibrary) ...[
                  const SizedBox(height: 12),
                  const FloatingActionButton.extended(
                    heroTag: 'addToLibFab',
                    onPressed: _addToLibrary,
                    label: Text('Add to Library'),
                    icon: Icon(Icons.library_add),
                  ),
                ],
              ],
            )
          : showExample
              ? FloatingActionButton.extended(
                  heroTag: 'exampleFab',
                  onPressed: _generatingExample ? null : _generateExampleSpot,
                  icon: _generatingExample
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('Generate Example Spot'),
                )
              : null,
      bottomNavigationBar: widget.readOnly
          ? null
          : (_showScrollIndicator && !_previewMode)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      waitDuration: const Duration(milliseconds: 500),
                      showDuration: const Duration(seconds: 2),
                      message:
                          'Scrolled: ${(_scrollProgress * 100).toStringAsFixed(1)}%',
                      child: LinearProgressIndicator(
                        value: _scrollProgress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary),
                        minHeight: 2,
                      ),
                    ),
                  ],
                )
              : null,
      body: hasSpots
          ? _previewMode
              ? Stack(
                  children: [
                    if (_previewPath != null)
                      Positioned.fill(
                        child: Image.file(File(_previewPath!), fit: BoxFit.cover),
                      ),
                    if (_previewPath != null)
                      Positioned.fill(child: Container(color: Colors.black54)),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IconButton(
                            icon: Icon(Icons.table_chart),
                            onPressed: _exportPreviewCsv,
                          ),
                          const IconButton(
                            icon: Icon(Icons.download),
                            onPressed: _exportPreviewJson,
                          ),
                          const IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: _exportPreviewSummary,
                          ),
                          const IconButton(
                            icon: Icon(Icons.description),
                            onPressed: _exportPreviewMarkdown,
                            onLongPress: _previewMarkdown,
                          ),
                          Badge.count(
                            count: mistakeCount,
                            isLabelVisible: mistakeCount > 0,
                            child: const IconButton(
                              icon: Icon(Icons.archive),
                              onPressed: _exportPreviewZip,
                            ),
                          ),
                          const IconButton(
                            icon: Icon(Icons.share),
                            onPressed: _sharePreviewZip,
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_originPreset != null) _buildPresetBanner(),
                          Stack(
                            children: [
                              LinearProgressIndicator(
                                value: evTotal,
                                color: primaryColor,
                                backgroundColor: Colors.white24,
                                minHeight: 4,
                              ),
                              LinearProgressIndicator(
                                value: icmTotal,
                                color: primaryColor.withOpacity(0.4),
                                backgroundColor: Colors.transparent,
                                minHeight: 4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                    if (coverageWarningNeeded) ...[
                      GestureDetector(
                        onTap: _calculateMissingEvIcm,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Coverage incomplete: EV/ICM not computed for all spots',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _CoverageProgress(
                      label: 'EV Covered',
                      value: evCoverage,
                      color: Theme.of(context).colorScheme.secondary,
                      message: _evTooltip,
                    ),
                    const SizedBox(height: 8),
                    _CoverageProgress(
                      label: 'ICM Covered',
                      value: icmCoverage,
                      color: Colors.purple,
                      message: _icmTooltip,
                    ),
                    const SizedBox(height: 16),
            TemplateSummaryPanel(
              spots: totalSpots,
              evCount: evCovered,
              icmCount: icmCovered,
              tags: summaryTags,
              avgEv: avgEv,
            ),
                    const SizedBox(height: 16),
                    if (heroEvsAll.isNotEmpty)
                      EvDistributionChart(evs: heroEvsAll),
                  ],
                    ),
                  ],
                )
              : Stack(
              children: [
                if (_showImportIndicator)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: 1,
                      color: Colors.green,
                      backgroundColor: Colors.transparent,
                      minHeight: 4,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_originPreset != null) _buildPresetBanner(),
                  Stack(
                    children: [
                      LinearProgressIndicator(
                        value: evTotal,
                        color: primaryColor,
                        backgroundColor: Colors.white24,
                        minHeight: 4,
                      ),
                      LinearProgressIndicator(
                        value: icmTotal,
                        color: primaryColor.withOpacity(0.4),
                        backgroundColor: Colors.transparent,
                        minHeight: 4,
                      ),
                    ],
                  ),
                  Tooltip(
                    message: 'Mistake-free = number of spots without mistakes',
                    child: LinearProgressIndicator(
                      value: mistakePct,
                      color: Colors.redAccent,
                      backgroundColor: Colors.transparent,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
            if (coverageWarningNeeded) ...[
              GestureDetector(
                onTap: _calculateMissingEvIcm,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Coverage incomplete: EV/ICM not computed for all spots',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _CoverageProgress(
              label: 'EV Covered',
              value: evCoverage,
              color: Theme.of(context).colorScheme.secondary,
              message: _evTooltip,
            ),
            const SizedBox(height: 8),
            _CoverageProgress(
              label: 'ICM Covered',
              value: icmCoverage,
              color: Colors.purple,
              message: _icmTooltip,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtr,
              focusNode: _descFocus,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onEditingComplete: _saveDesc,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _evCtr,
              decoration:
                  const InputDecoration(labelText: 'Min EV to be correct (bb)'),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0.01;
                setState(() => widget.template.minEvForCorrect = val);
                _markAllDirty();
                _persist();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _anteCtr,
              decoration: const InputDecoration(labelText: 'Ante (BB)'),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                var val = int.tryParse(v) ?? 0;
                if (val < 0) val = 0;
                if (val > 5) val = 5;
                if (_anteCtr.text != '$val') {
                  _anteCtr.text = '$val';
                  _anteCtr.selection = TextSelection.fromPosition(
                      TextPosition(offset: _anteCtr.text.length));
                }
                setState(() => widget.template.anteBb = val);
                _markAllDirty();
                _persist();
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
                      _persist();
                    },
                  ),
                const InputChip(
                  label: Text('+ Add'),
                  onPressed: _addPackTag,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in widget.template.focusTags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() => widget.template.focusTags.remove(tag));
                      _persist();
                    },
                  ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _focusCtr,
                    decoration: const InputDecoration(hintText: 'Focus tag'),
                    onSubmitted: (v) => _addFocusTag(v.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final t in widget.template.focusHandTypes)
                  InputChip(
                    label: Text(t.toString()),
                    onDeleted: () {
                      setState(() => widget.template.focusHandTypes.remove(t));
                      _persist();
                      if (mounted) setState(() {});
                    },
                  ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _handTypeCtr,
                    decoration: const InputDecoration(hintText: 'Hand type'),
                    onSubmitted: (v) => _addHandType(v.trim()),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('e.g. JXs, 76s+, suited connectors',
                  style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 8),
            if (handCounts.isNotEmpty)
              ExpansionTile(
                title: Row(
                  children: [
                    const Text('Focus coverage'),
                    const SizedBox(width: 8),
                    Text(
                      '(avg ${focusAvg == null ? 'N/A' : '${focusAvg.round()}%'})',
                      style: TextStyle(
                        color: focusAvg == null
                            ? Colors.white
                            : focusAvg < 70
                                ? Colors.red
                                : focusAvg < 90
                                    ? Colors.yellow
                                    : Colors.green,
                      ),
                    ),
                  ],
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                collapsedTextColor: Colors.white,
                textColor: Colors.white,
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final g in widget.template.focusHandTypes)
                        (() {
                          final count = handCounts[g.label] ?? 0;
                          final total = handTotals[g.label] ?? 0;
                          final pct = total == 0 ? 0 : (count * 100 / total).round();
                          final bg = pct < 70 ? Colors.red : Colors.grey[800];
                          return Chip(
                            backgroundColor: bg,
                            label: Text(
                              '${g.label}: $count/$total ($pct%)',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        })(),
                    ],
                  ),
                ],
              ),
            if (_catStats.isNotEmpty)
              ExpansionTile(
                title: const Text('Category Stats',
                    style: TextStyle(color: Colors.white)),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                collapsedTextColor: Colors.white,
                textColor: Colors.white,
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  DataTable(
                    headingRowHeight: 28,
                    dataRowHeight: 28,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(
                          label: Text('Category',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          numeric: true,
                          label: Text('Acc',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          numeric: true,
                          label: Text('EV',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          numeric: true,
                          label: Text('ICM',
                              style: TextStyle(color: Colors.white))),
                    ],
                    rows: [
                      for (final e in _catStats.entries)
                        DataRow(cells: [
                          DataCell(Text(e.key,
                              style: const TextStyle(color: Colors.white))),
                          DataCell(Text('${(e.value.acc * 100).round()}%',
                              style:
                                  const TextStyle(color: Colors.white70))),
                          DataCell(Text(e.value.ev.toStringAsFixed(2),
                              style:
                                  const TextStyle(color: Colors.white70))),
                          DataCell(Text(e.value.icm.toStringAsFixed(2),
                              style:
                                  const TextStyle(color: Colors.white70))),
                        ])
                    ],
                  )
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
                _persist();
              },
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, set) => EvSummaryCard(
                values: _summaryIcm ? icmVals : chipVals,
                isIcm: _summaryIcm,
                onToggle: () => set(() => _summaryIcm = !_summaryIcm),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: RangeMatrixPicker(
                  selected: range,
                  highlight: widget.template.heroRange?.toSet(),
                  onChanged: (_) {},
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const RangeLegend(),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Edit History', style: TextStyle(color: Colors.white)),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              collapsedTextColor: Colors.white,
              textColor: Colors.white,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_history.history.isEmpty)
                  const ListTile(
                    dense: true,
                    title: Text('No changes yet', style: TextStyle(color: Colors.white70)),
                  )
                else
                  for (final entry in historyGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(entry.key, style: const TextStyle(color: Colors.white70)),
                    ),
                    for (final e in entry.value)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          e.action == 'Added'
                              ? Icons.add_circle
                              : e.action == 'Deleted'
                                  ? Icons.remove_circle
                                  : e.action == 'Tagged'
                                      ? Icons.local_offer
                                      : e.action == 'Untagged'
                                          ? Icons.local_offer_outlined
                                          : Icons.edit,
                          color: e.action == 'Added'
                              ? Colors.green
                              : e.action == 'Deleted'
                                  ? Colors.red
                                  : e.action == 'Tagged'
                                      ? Colors.orange
                                      : e.action == 'Untagged'
                                          ? Colors.grey
                                          : Colors.blue,
                        ),
                        title: Text('${e.action}: ${e.title}',
                            style: const TextStyle(color: Colors.white)),
                        trailing: Text(DateFormat.Hm().format(e.time),
                            style: const TextStyle(color: Colors.white70)),
                      ),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            if (!narrow)
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
                        ButtonSegment(value: 'ok', label: Text('OK')),
                        ButtonSegment(value: 'error', label: Text('Errors')),
                        ButtonSegment(value: 'empty', label: Text('Empty')),
                      ],
                      selected: {_evFilter},
                      onSelectionChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v.first;
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _evFilter,
                      decoration: const InputDecoration(labelText: 'EV'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'ok', child: Text('OK')),
                        DropdownMenuItem(value: 'error', child: Text('Errors')),
                        DropdownMenuItem(value: 'empty', child: Text('Empty')),
                      ],
                      onChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v ?? 'all';
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EV range (BB)',
                          style: TextStyle(color: Colors.white70)),
                      RangeSlider(
                        values: _evRange,
                        min: -5,
                        max: 5,
                        divisions: 100,
                        labels: RangeLabels(
                          _evRange.start.toStringAsFixed(1),
                          _evRange.end.toStringAsFixed(1),
                        ),
                        onChanged: (v) async {
                          setState(() => _evRange = v);
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setString(
                              _prefsEvRangeKey, '${v.start},${v.end}');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_evRange.start.toStringAsFixed(1)} … ${_evRange.end.toStringAsFixed(1)} BB',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() => _evRange = const RangeValues(-5, 5));
                    prefs.setString(_prefsEvRangeKey, '-5.0,5.0');
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _generatingAll ? null : _generateAllEv,
                    child: _generatingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate All'),
                  ),
                  ElevatedButton(
                    onPressed: _generatingIcm ? null : _generateAllIcm,
                    child: _generatingIcm
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate ICM'),
                  ),
                  const ElevatedButton(
                    onPressed: _recalculateAll,
                    child: Text('Recalculate All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TemplateSummaryPanel(
              spots: totalSpots,
              evCount: evCovered,
              icmCount: icmCovered,
              tags: summaryTags,
              avgEv: avgEv,
            ),
            const SizedBox(height: 8),
            _EvCoverageBar(ev: evCoverage, icm: icmCoverage, both: bothCoverage),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _tagFilter ?? '',
                decoration: const InputDecoration(labelText: 'Filter by tag'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All')),
                  for (final t in widget.template.spots
                      .expand((s) => s.tags)
                      .toSet()
                      .toList()
                    ..sort())
                    DropdownMenuItem(value: t.toLowerCase(), child: Text(t)),
                ],
                onChanged: (v) async {
                  setState(
                      () => _tagFilter = (v == null || v.isEmpty) ? null : v);
                  _storeTagFilter();
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hero push only'),
              value: _heroPushOnly,
              onChanged: (v) => setState(() => _heroPushOnly = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Mistakes'),
                    selected: _filterMistakes,
                    onSelected: (v) => setState(() => _filterMistakes = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Outdated'),
                    selected: _filterOutdated,
                    onSelected: (v) => setState(() => _filterOutdated = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('EV Covered'),
                    selected: _filterEvCovered,
                    onSelected: (v) => setState(() => _filterEvCovered = v),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              title: const Text('Only Changed'),
              value: _changedOnly,
              onChanged: (v) => setState(() => _changedOnly = v ?? false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<SpotSort>(
                value: _spotSort,
                decoration: const InputDecoration(labelText: 'Sort'),
                items: const [
                  DropdownMenuItem(
                      value: SpotSort.original, child: Text('Default')),
                  DropdownMenuItem(value: SpotSort.evDesc, child: Text('EV ↓')),
                  DropdownMenuItem(value: SpotSort.evAsc, child: Text('EV ↑')),
                  DropdownMenuItem(value: SpotSort.icmDesc, child: Text('ICM ↓')),
                  DropdownMenuItem(value: SpotSort.icmAsc, child: Text('ICM ↑')),
                  DropdownMenuItem(
                      value: SpotSort.priorityDesc, child: Text('Priority')),
                ],
                onChanged: (v) =>
                    setState(() => _spotSort = v ?? SpotSort.original),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final rows = _buildRows(sorted);
                  return NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      _scrollDebounce?.cancel();
                      _scrollDebounce =
                          Timer(const Duration(milliseconds: 300), _storeScroll);
                      return false;
                    },
                    child: DragAutoScroll(
                      controller: _scrollCtrl,
                      child: ReorderableListView.builder(
                        key: const PageStorageKey('spotsList'),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: rows.length,
                        proxyDecorator: _proxyLift,
                        onReorder: (oldIndex, newIndex) {
                          final moved = rows.removeAt(oldIndex);
                          rows.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, moved);
                          _recordSnapshot();
                          widget.template.spots
                            ..clear()
                            ..addAll(rows.where((r) => r.kind == _RowKind.spot).map((r) => r.spot!));
                          _persist();
                          WidgetsBinding.instance.addPostFrameCallback((_) =>
                              _focusSpot(moved.spot?.id ?? ''));
                        },
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          if (r.kind == _RowKind.header) {
                            return Padding(
                              key: ValueKey('hdr_${r.tag}'),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Text(
                                r.tag.isEmpty ? 'Untagged' : r.tag,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            );
                          }
                          final spot = r.spot!;
                          final selected = _selectedSpotIds.contains(spot.id);
                          final showDup =
                              (spot.isNew && _importDuplicateGroups([spot])) ||
                                  _isDup(spot);
                          final content = ReorderableDragStartListener(
                            key: ValueKey(spot.id),
                            index: i,
                            child: InkWell(
                            onTap: () async {
                              await showSpotViewerDialog(
                                context,
                                spot,
                                templateTags: widget.template.tags,
                              );
                              if (_autoSortEv) setState(() => _sortSpots());
                              _focusSpot(spot.id);
                            },
                            onLongPress: () {
                              setState(() => _selectedSpotIds.add(spot.id));
                              _maybeShowMultiTip();
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: RepaintBoundary(
                                key: _itemKeys.putIfAbsent(spot.id, () => GlobalKey()),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  color: spot.id == _highlightId
                                          ? Colors.yellow.withOpacity(0.3)
                                          : spot.isNew
                                              ? Colors.yellow.withOpacity(0.1)
                                              : spot.dirty
                                                  ? Colors.blue.withOpacity(0.05)
                                                  : null,
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                                      if (_isMultiSelect)
                                        Checkbox(
                                          value: selected,
                                          onChanged: (_) {
                                            setState(() {
                                              if (selected) {
                                                _selectedSpotIds.remove(spot.id);
                                              } else {
                                                _selectedSpotIds.add(spot.id);
                                              }
                                            });
                                            _maybeShowMultiTip();
                                          },
                                        ),
                                      Expanded(
                                        child: TrainingPackSpotPreviewCard(
                                          spot: spot,
                                          editableTitle: true,
                                          onTitleChanged: (_) {
                                            setState(() {});
                                            _persist();
                                          },
                                          isMistake: spot.evalResult?.correct == false,
                                          titleColor: spot.evalResult == null
                                              ? Colors.yellow
                                              : (spot.evalResult!.correct ? null : Colors.red),
                                          onHandEdited: () {
                                            unawaited(() async {
                                              try {
                                                spot.dirty = false;
                                                await context.read<EvaluationExecutorService>().evaluateSingle(
                                                      context,
                                                      spot,
                                                      template: widget.template,
                                                      anteBb: widget.template.anteBb,
                                                    );
                                              } catch (_) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Evaluation failed')));
                                                }
                                              }
                                              if (!mounted) return;
                                              setState(() {
                                                if (_autoSortEv) _sortSpots();
                                              });
                                              await _persist();
                                            }());
                                          },
                                          onTagTap: (tag) async {
                                            setState(() => _tagFilter = tag);
                                            _storeTagFilter();
                                          },
                                          template: widget.template,
                                          persist: _persist,
                                          focusSpot: _focusSpot,
                                          onNewTap: _selectAllNew,
                                          onDupTap: _selectAllDuplicates,
                                          onPersist: _persist,
                                          showDuplicate: showDup,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildSpotMenu(spot),
                                          TextButton(
                                            onPressed: () => _openEditor(spot),
                                            child: const Text('📝 Edit'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: () {
                                              final evalSpot = _toSpot(spot);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => SpotSolveScreen(
                                                    spot: evalSpot,
                                                    packSpot: spot,
                                                    template: widget.template,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Remove this spot from the pack?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('Remove'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok ?? false) {
                                                final t = spot.title;
                                                setState(() => widget.template.spots.removeAt(
                                                    widget.template.spots.indexOf(spot)));
                                                await _persist();
                                                setState(() => _history.log('Deleted', t, spot.id));
                                              }
                                            },
                                          ),
                                          if (_isMultiSelect)
                                            const IconButton(
                                              icon: Icon(Icons.delete_forever, color: Colors.red),
                                              onPressed: _bulkDeleteQuick,
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
                                final t = spot.title;
                                setState(() => widget.template.spots.remove(spot));
                                _persist();
                                setState(() => _history.log('Deleted', t, spot.id));
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
                                        _persist();
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
                      ),
                    ),
                  );
                },
              ),
            ),
            ],
          ),
        ),
        )
            : Stack(
                children: [
                  if (_showImportIndicator)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: 1,
                        color: Colors.green,
                        backgroundColor: Colors.transparent,
                        minHeight: 4,
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  const Icon(Icons.lightbulb_outline, size: 96, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    showExample
                        ? 'This pack is empty. Tap + to add a spot, 📋 to paste from JSON or use the wand to generate an example'
                        : 'This pack is empty. Tap + to add your first spot or 📋 to paste from JSON',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showExample) ...[
                        ElevatedButton.icon(
                          onPressed:
                              _generatingExample ? null : _generateExampleSpot,
                          icon: _generatingExample
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_fix_high),
                          label: const Text('Example'),
                        ),
                        const SizedBox(width: 12),
                      ],
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
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pasteHandHistory,
                        icon: const Text('📥'),
                        label: const Text('Paste Hand'),
                      ),
                    ],
                  ),
                ],
              ),
            );
  }
}

class _TemplatePreviewCard extends StatefulWidget {
  final TrainingPackTemplate template;
  const _TemplatePreviewCard({required this.template});

  @override
  State<_TemplatePreviewCard> createState() => _TemplatePreviewCardState();
}

class _TemplatePreviewCardState extends State<_TemplatePreviewCard> {
  String? previewPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final png = widget.template.png;
    if (png != null) {
      final path = await PreviewCacheService.instance.getPreviewPath(png);
      if (!mounted) return;
      setState(() => previewPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (widget.template.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(widget.template.description),
              ),
            if (widget.template.focusTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('🎯 Focus: ${widget.template.focusTags.join(', ')}'),
              ),
            if (widget.template.focusHandTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('🎯 Hand Goal: ${widget.template.focusHandTypes.join(', ')}'),
              ),
            if (widget.template.heroRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.template.handTypeSummary(),
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Spots: ${widget.template.spots.length}'),
              ),
          ],
        ),
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (previewPath != null)
            Positioned.fill(
              child: Image.file(File(previewPath!), fit: BoxFit.cover),
            ),
          if (previewPath != null)
            Positioned.fill(child: Container(color: Colors.black45)),
          content,
        ],
      ),
    );
  }
}

class _ManageTagTile extends StatefulWidget {
  final String tag;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  const _ManageTagTile({super.key, required this.tag, required this.onRename, required this.onDelete});

  @override
  State<_ManageTagTile> createState() => _ManageTagTileState();
}

class _ManageTagTileState extends State<_ManageTagTile> {
  late TextEditingController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = TextEditingController(text: widget.tag);
  }

  @override
  void didUpdateWidget(covariant _ManageTagTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) _ctr.text = widget.tag;
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Text('✏️'),
      title: TextField(
        controller: _ctr,
        decoration: const InputDecoration(border: InputBorder.none),
        onSubmitted: (v) {
          final t = v.trim();
          if (t.isEmpty || t == widget.tag) {
            _ctr.text = widget.tag;
          } else {
            widget.onRename(t);
          }
        },
      ),
      trailing: IconButton(
        icon: const Text('🗑️'),
        onPressed: widget.onDelete,
      ),
    );
  }
}

class _EvCoverageBar extends StatelessWidget {
  final double ev;
  final double icm;
  final double both;
  const _EvCoverageBar({required this.ev, required this.icm, required this.both});

  Widget _bar(BuildContext context, double value, String label, Color color) {
    final percent = (value * 100).round();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text('$label $percent%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Row(
      children: [
        _bar(context, ev, 'EV', accent),
        const SizedBox(width: 8),
        _bar(context, icm, 'ICM', Colors.purple),
        const SizedBox(width: 8),
        _bar(context, both, 'Both', Colors.green),
      ],
    );
  }
}

const _evTooltip = 'Calculated expected value (EV) for this spot';
const _icmTooltip = 'Calculated equity in tournament ICM model';

class _CoverageProgress extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String message;
  const _CoverageProgress({
    required this.label,
    required this.value,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).toStringAsFixed(0)}%';
    final offset = MediaQuery.of(context).padding.top;
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 300),
      preferBelow: false,
      preferAbove: false,
      verticalOffset: offset,
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                Text(percent, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _RowKind { header, spot }

class _Row {
  final _RowKind kind;
  final String tag;
  final TrainingPackSpot? spot;
  const _Row.header(this.tag)
      : kind = _RowKind.header,
        spot = null;
  const _Row.spot(this.spot)
      : kind = _RowKind.spot,
        tag = '';
}

TrainingPackSpot? _copiedSpot;
class UndoIntent extends Intent { const UndoIntent(); }
class RedoIntent extends Intent { const RedoIntent(); }
class DeleteBulkIntent extends Intent { const DeleteBulkIntent(); }
class DuplicateBulkIntent extends Intent { const DuplicateBulkIntent(); }
class TagBulkIntent extends Intent { const TagBulkIntent(); }

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final List<TrainingPackTemplate> templates;
  final bool readOnly;
  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    required this.templates,
    this.readOnly = false,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() => _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState extends State<TrainingPackTemplateEditorScreen> with SpotListSection, TemplateSettingsSection {
  late final TextEditingController _descCtr;
  late final TextEditingController _evCtr;
  late final TextEditingController _anteCtr;
  late final TextEditingController _focusCtr;
  late final TextEditingController _handTypeCtr;
  late final FocusNode _descFocus;
  late String _templateName;
  final String _query = '';
  String? _tagFilter;
  late TextEditingController _searchCtrl;
  late TextEditingController _tagSearchCtrl;
  final String _tagSearch = '';
  final Set<String> _selectedTags = {};
  final Set<String> _selectedSpotIds = {};
  bool get _isMultiSelect => _selectedSpotIds.isNotEmpty;
  final SortBy _sortBy = SortBy.manual;
  final bool _autoSortEv = false;
  final bool _pinnedOnly = false;
  final bool _heroPushOnly = false;
  final bool _filterMistakes = false;
  final bool _filterOutdated = false;
  final bool _filterEvCovered = false;
  final bool _changedOnly = false;
  final bool _duplicatesOnly = false;
  final bool _newOnly = false;
  final bool _showMissingOnly = false;
  int? _priorityFilter;
  final FocusNode _focusNode = FocusNode();
  final bool _filtersShown = false;
  List<TrainingPackSpot>? _lastRemoved;
  static const _prefsAutoSortKey = 'auto_sort_ev';
  static const _prefsEvFilterKey = 'ev_filter';
  static const _prefsEvRangeKey = 'ev_range';
  static const _prefsTagFilterKey = 'tag_filter';
  static const _prefsQuickFilterKey = 'quick_filter';
  static const _prefsSortKey = 'sort_mode';
  static const _prefsScrollPrefix = 'template_scroll_';
  static const _prefsSortModeKey = 'templateSortMode';
  static const _prefsDupOnlyKey = 'dup_only';
  static const _prefsPinnedOnlyKey = 'pinned_only';
  static const _prefsNewOnlyKey = 'new_only';
  static const _prefsPriorityFilterKey = 'priority_filter';
  static const _prefsSortMode2Key = 'sort_mode2';
  static const _prefsPreviewModeKey = 'preview_mode';
  static const _prefsPreviewJsonPngKey = 'preview_json_png';
  static const _prefsMultiTipKey = 'multi_tip_shown';
  static String _trainedPromptKey(String tplId) => '_trainPrompt_$tplId';
  String _scrollKeyFor(TrainingPackTemplate t) => '$_prefsScrollPrefix${t.id}';
  String get _scrollKey => _scrollKeyFor(widget.template);
  final String _evFilter = 'all';
  final RangeValues _evRange = const RangeValues(-5, 5);
  final bool _evAsc = false;
  final bool _sortEvAsc = false;
  final bool _mistakeFirst = false;
  final SpotSort _spotSort = SpotSort.original;
  final SortMode _sortMode = SortMode.position;
  static const _quickFilters = [
    'BTN',
    'SB',
    'Hero push only',
    'Mistake spots',
    'High priority'
  ];
  String? _quickFilter;
  String? _positionFilter;
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _scrollDebounce;
  final Map<String, GlobalKey> _itemKeys = {};
  String? _highlightId;
  final bool _summaryIcm = false;
  final bool _evaluatingAll = false;
  final bool _generatingAll = false;
  final bool _generatingIcm = false;
  final bool _generatingExample = false;
  final bool _calculatingMissing = false;
  final double _calcProgress = 0;
  final bool _cancelRequested = false;
  final bool _exportingBundle = false;
  final bool _exportingPreview = false;
  final bool _showPasteBubble = false;
  Timer? _clipboardTimer;
  final bool _showImportIndicator = false;
  final bool _showDupHint = false;
  bool _multiTipShown = false;
  Timer? _importTimer;
  List<TrainingPackSpot>? _pasteUndo;
  late final UndoRedoService _history;
  final List<TemplateSnapshot> _snapshots = [];
  final bool _loadingEval = false;
  double _scrollProgress = 0;
  bool _showScrollIndicator = false;
  Timer? _scrollThrottle;
  final bool _previewMode = false;
  final bool _previewJsonPng = false;
  String? _previewPath;
  TrainingPackPreset? _originPreset;
  bool get _canUndo => _history.canUndo;
  bool get _canRedo => _history.canRedo;

  void _storeTagFilter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsTagFilterKey, _tagFilter ?? '');
  }

  void _storeQuickFilter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsQuickFilterKey, _quickFilter ?? '');
  }

  void _storeSort() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortKey, _sortBy.name);
  }

  void _storePreview() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsPreviewModeKey, _previewMode);
  }

  void _storePreviewJsonPng() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsPreviewJsonPngKey, _previewJsonPng);
  }

  void _storeScroll() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = _scrollCtrl.offset;
    if (offset > 100) {
      prefs.setDouble(_scrollKey, offset);
    } else {
      prefs.remove(_scrollKey);
    }
  }

  void _updateScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final progress = max > 0 ? _scrollCtrl.position.pixels / max : 0.0;
    final show = max >= 200;
    if (progress != _scrollProgress || show != _showScrollIndicator) {
      setState(() {
        _scrollProgress = progress;
        _showScrollIndicator = show;
      });
    }
  }

  Future<void> _maybeShowMultiTip() async {
    if (_multiTipShown || _selectedSpotIds.isEmpty) return;
    _multiTipShown = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsMultiTipKey, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip: Ctrl + click to multi-select, Ctrl + D to duplicate…')),
      );
    }
  }

  void _storeDupOnly() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsDupOnlyKey, _duplicatesOnly);
  }

  void _storePinnedOnly() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsPinnedOnlyKey, _pinnedOnly);
  }

  void _storeNewOnly() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefsNewOnlyKey, _newOnly);
  }

  void _storeSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortMode2Key, _sortMode.name);
  }

  Set<String> _spotHands() {
    final set = <String>{};
    for (final s in widget.template.spots) {
      final code = handCode(s.hand.heroCards);
      if (code != null) set.add(code);
    }
    return set;
  }

  Set<String> _rangeHands() {
    final range = widget.template.heroRange;
    if (range != null && range.isNotEmpty) {
      return {for (final h in range) h.toUpperCase()};
    }
    return _spotHands();
  }

  Map<String, int> _handTypeCounts() {
    final hands = _spotHands();
    final res = <String, int>{};
    for (final g in widget.template.focusHandTypes) {
      var count = 0;
      for (final code in hands) {
        if (matchHandTypeLabel(g.label, code)) count++;
      }
      res[g.label] = count;
    }
    return res;
  }

  Map<String, int> _handTypeTotals() {
    final hands = _rangeHands();
    final res = <String, int>{};
    for (final g in widget.template.focusHandTypes) {
      var count = 0;
      for (final code in hands) {
        if (matchHandTypeLabel(g.label, code)) count++;
      }
      res[g.label] = count;
    }
    return res;
  }

  }

  @override
  void initState() {
    super.initState();
    _templateName = widget.template.name;
    _descCtr = TextEditingController(text: widget.template.description);
    _evCtr = TextEditingController(
        text: widget.template.minEvForCorrect.toString());
    _anteCtr = TextEditingController(text: widget.template.anteBb.toString());
    _focusCtr = TextEditingController();
    _handTypeCtr = TextEditingController();
    _descFocus = FocusNode();
    _descFocus.addListener(() {
      if (!_descFocus.hasFocus) _saveDesc();
    });
    _searchCtrl = TextEditingController();
    _tagSearchCtrl = TextEditingController();
    _history = UndoRedoService(eventsLimit: 50);
    _history.record(widget.template.spots);
    final needs = widget.template.spots
        .any((s) => s.heroEv == null || s.heroIcmEv == null);
    if (needs) {
      setState(() => _loadingEval = true);
      BulkEvaluatorService()
          .generateMissing(widget.template, onProgress: null)
          .then((_) {
        TemplateCoverageUtils.recountAll(widget.template);
        if (mounted) setState(() => _loadingEval = false);
      });
    }
    _scrollCtrl.addListener(() {
      if (_scrollThrottle?.isActive ?? false) return;
      _scrollThrottle =
          Timer(const Duration(milliseconds: 100), _updateScroll);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScroll();
      _maybeStartTraining();
    });
    _clipboardTimer ??=
        Timer.periodic(const Duration(seconds: 2), (_) => _checkClipboard());
    _checkClipboard();
    SharedPreferences.getInstance().then((prefs) {
      final auto = prefs.getBool(_prefsAutoSortKey) ?? false;
      final filter = prefs.getString(_prefsEvFilterKey) ?? 'all';
      final rangeStr = prefs.getString(_prefsEvRangeKey);
      final tag = prefs.getString(_prefsTagFilterKey);
      final quick = prefs.getString(_prefsQuickFilterKey);
      final sortStr = prefs.getString(_prefsSortKey);
      final sortMode = prefs.getString(_prefsSortModeKey);
      final mode2 = prefs.getString(_prefsSortMode2Key);
      final offset = prefs.getDouble(_scrollKey) ?? 0;
      final dupOnly = prefs.getBool(_prefsDupOnlyKey) ?? false;
      final pinnedOnly = prefs.getBool(_prefsPinnedOnlyKey) ?? false;
      final newOnly = prefs.getBool(_prefsNewOnlyKey) ?? false;
      final priorityFilter = prefs.getInt(_prefsPriorityFilterKey);
      final preview = prefs.getBool(_prefsPreviewModeKey) ?? false;
      final png = prefs.getBool(_prefsPreviewJsonPngKey) ?? false;
      final multiTip = prefs.getBool(_prefsMultiTipKey) ?? false;
      final snapsRaw = prefs.getString('tpl_snapshots_${widget.template.id}');
      var range = const RangeValues(-5, 5);
      if (rangeStr != null) {
        final parts = rangeStr.split(',');
        if (parts.length == 2) {
          final start = double.tryParse(parts[0]);
          final end = double.tryParse(parts[1]);
          if (start != null && end != null) {
            range = RangeValues(start, end);
          }
        }
      }
      List<TemplateSnapshot> snaps = [];
      if (snapsRaw != null) {
        try {
          final list = jsonDecode(snapsRaw) as List;
          snaps = [
            for (final s in list)
              TemplateSnapshot.fromJson(Map<String, dynamic>.from(s as Map))
          ];
        } catch (_) {}
      }
      SortBy sort = SortBy.manual;
      if (sortStr != null) {
        for (final v in SortBy.values) {
          if (v.name == sortStr) {
            sort = v;
            break;
          }
        }
      }
      if (sortMode != null) _evAsc = sortMode == 'asc';
      if (mounted) {
        setState(() {
          _autoSortEv = auto;
          _evFilter = filter;
          _evRange = range;
          _tagFilter = tag?.isEmpty ?? true ? null : tag;
          _quickFilter = quick?.isEmpty ?? true ? null : quick;
          _sortBy = sort;
          _duplicatesOnly = dupOnly;
          _pinnedOnly = pinnedOnly;
          _newOnly = newOnly;
          _priorityFilter = priorityFilter;
          _snapshots = snaps;
          _previewMode = preview;
          _previewJsonPng = png;
          _multiTipShown = multiTip;
          _loadPreview();
          if (widget.readOnly) _previewMode = true;
      if (mode2 != null) {
            for (final v in SortMode.values) {
              if (v.name == mode2) _sortMode = v;
            }
          }
          if (sortMode != null) _sortSpots();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            final max = _scrollCtrl.position.maxScrollExtent;
            _scrollCtrl.jumpTo(min(offset, max));
            _updateScroll();
          }
        });
        _ensureEval();
      }
    });
    TrainingPackPresetRepository.getAll().then((list) {
      final p = list.firstWhereOrNull((e) => e.id == widget.template.id);
      if (p != null && mounted) setState(() => _originPreset = p);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filtersShown && MediaQuery.of(context).size.width < 400) {
      _filtersShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _storeScroll();
    _descFocus.dispose();
    _descCtr.dispose();
    _evCtr.dispose();
    _anteCtr.dispose();
    _focusCtr.dispose();
    _handTypeCtr.dispose();
    _searchCtrl.dispose();
    _tagSearchCtrl.dispose();
    _scrollThrottle?.cancel();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _clipboardTimer?.cancel();
    _importTimer?.cancel();
    super.dispose();
  }

  void _save() {
    _saveDesc();
    if (widget.template.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final ready = validateTrainingPackTemplate(widget.template).isEmpty;
    widget.template.isDraft = !ready;
    TemplateCoverageUtils.recountAll(widget.template);
    TrainingPackStorage.save(widget.templates);
    unawaited(
      BulkEvaluatorService()
          .generateMissing(widget.template, onProgress: null)
          .then((_) {
        final ctx = navigatorKey.currentState?.context;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('EV/ICM updated'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }),
    );
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
    if (_exportingBundle) return null;
    setState(() => _exportingBundle = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/template_bundle');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create();
      final jsonFile = File('${dir.path}/template.json');
      await jsonFile.writeAsString(jsonEncode(widget.template.toJson()));
      for (int i = 0; i < widget.template.spots.length; i++) {
        final spot = widget.template.spots[i];
        final preview = TrainingPackSpotPreviewCard(spot: spot);
        final label = spot.title.isNotEmpty ? spot.title : 'Spot ${i + 1}';
        final bytes = await PngExporter.exportSpot(preview, label: label);
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
    } finally {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) setState(() => _exportingBundle = false);
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

  Future<void> _exportPackBundle() async {
    if (_exportingBundle) return;
    setState(() => _exportingBundle = true);
    try {
      final file = await PackExportService.exportBundle(widget.template);
      if (!mounted) return;
      await FileSaverService.instance.saveZip(file.path);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bundle exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingBundle = false);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final file = await PackExportService.exportToCsv(widget.template);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CSV exported')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
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

  Future<Uint8List?> _capturePreview() {
    return PngExporter.exportWidget(
      _TemplatePreviewCard(template: widget.template),
    );
  }

  Future<void> _exportPreview() async {
    if (_exportingPreview) return;
    setState(() => _exportingPreview = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await _capturePreview();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Не удалось создать превью')));
        }
        return;
      }
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Не удалось сохранить превью')));
      }
    } finally {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) setState(() => _exportingPreview = false);
    }
  }

  Future<void> _exportPreviewJson() async {
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    var pngName = name;
    if (_previewJsonPng) {
      final c = TextEditingController(text: pngName);
      final res = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PNG name'),
          content: TextField(controller: c, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
          ],
        ),
      );
      if (res != null && res.isNotEmpty) pngName = res;
    }
    try {
      await FileSaverService.instance.saveJson(name, widget.template.toJson());
      if (_previewJsonPng) {
        final bytes = await _capturePreview();
        if (bytes != null) {
          await FileSaverService.instance.savePng(pngName, bytes);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _exportPreviewSummary() async {
    final spots = widget.template.spots;
    final total = spots.length;
    final evCovered = spots.where((s) => s.heroEv != null && !s.dirty).length;
    final icmCovered =
        spots.where((s) => s.heroIcmEv != null && !s.dirty).length;
    final data = {
      'id': widget.template.id,
      'name': widget.template.name,
      'spotCount': total,
      'evCoverage': total == 0 ? 0.0 : evCovered / total,
      'icmCoverage': total == 0 ? 0.0 : icmCovered / total,
    };
    final safe =
        widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_summary_$safe';
    try {
      await FileSaverService.instance.saveJson(name, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  String _generatePreviewMarkdown() {
    final spots = widget.template.spots;
    final total = spots.length;
    final evCovered = spots.where((s) => s.heroEv != null && !s.dirty).length;
    final icmCovered =
        spots.where((s) => s.heroIcmEv != null && !s.dirty).length;
    final buffer = StringBuffer()
      ..writeln('# ${widget.template.name}')
      ..writeln('- **ID:** ${widget.template.id}')
      ..writeln('- **Spots:** $total')
      ..writeln(
          '- **EV coverage:** ${total == 0 ? 0 : (evCovered / total * 100).toStringAsFixed(1)}%')
      ..writeln(
          '- **ICM coverage:** ${total == 0 ? 0 : (icmCovered / total * 100).toStringAsFixed(1)}%')
      ..writeln(
          '- **Created:** ${DateFormat('yyyy-MM-dd').format(widget.template.createdAt)}');
    final tags = widget.template.tags.toSet().where((e) => e.isNotEmpty).toList();
    if (tags.isNotEmpty) buffer.writeln('- **Tags:** ${tags.join(', ')}');
    return buffer.toString().trimRight();
  }

  Future<void> _exportPreviewMarkdown([String? md]) async {
    md ??= _generatePreviewMarkdown();
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    try {
      await FileSaverService.instance.saveMd(name, md);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Markdown saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _previewMarkdown() async {
    final md = _generatePreviewMarkdown();
    final ok = await showMarkdownPreviewDialog(context, md);
    if (ok == true) await _exportPreviewMarkdown(md);
  }

  void _showMarkdownPreview() {
    showDialog(
      context: context,
      builder: (_) => MarkdownPreviewDialog(template: widget.template),
    );
  }

  Future<void> _exportPreviewCsv() async {
    final rows = <List<dynamic>>[
      ['Position', 'HeroCards', 'Board', 'EV', 'Tags']
    ];
    for (final s in widget.template.spots) {
      final h = s.hand;
      rows.add([
        h.position.name,
        h.heroCards,
        h.board.join(' '),
        s.heroEv?.toStringAsFixed(2) ?? '',
        s.tags.join('|'),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    try {
      await FileSaverService.instance.saveCsv(name, csvStr);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('CSV saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _exportPreviewZip() async {
    final archive = Archive();
    final jsonData = utf8.encode(jsonEncode(widget.template.toJson()));
    archive.addFile(ArchiveFile('template.json', jsonData.length, jsonData));
    final dir = await TrainingPackStorage.previewImageDir(widget.template);
    if (await dir.exists()) {
      for (final file in dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.png'))) {
        final bytes = await file.readAsBytes();
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }
    final bytes = ZipEncoder().encode(archive);
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = 'preview_$safe';
    try {
      await FileSaverService.instance.saveZip(name, Uint8List.fromList(bytes));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ZIP saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _sharePreviewZip() async {
    final archive = Archive();
    final jsonData = utf8.encode(jsonEncode(widget.template.toJson()));
    archive.addFile(ArchiveFile('template.json', jsonData.length, jsonData));
    final dir = await TrainingPackStorage.previewImageDir(widget.template);
    if (await dir.exists()) {
      for (final file
          in dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.png'))) {
        final bytes = await file.readAsBytes();
        final name = file.path.split(Platform.pathSeparator).last;
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }
    await Future.delayed(Duration.zero);
    final bytes = ZipEncoder().encode(archive);
    final tmp = await getTemporaryDirectory();
    final safe = widget.template.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(
        '${tmp.path}/preview_${safe}_${DateTime.now().millisecondsSinceEpoch}.zip');
    await file.writeAsBytes(bytes, flush: true);
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {}
    if (await file.exists()) await file.delete();
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
    _recordSnapshot();
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
      _persist();
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
      _recordSnapshot();
      setState(() => widget.template.spots.clear());
      _persist();
      setState(() => _history.log('Deleted', 'all spots', ''));
    }
  }

  Future<void> _clearTags() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear tags for all spots?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok ?? false) {
      _recordSnapshot();
      setState(() {
        for (final s in widget.template.spots) {
          s.tags.clear();
        }
      });
      await _persist();
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

  Future<void> _validateAllSpots() async {
    final issues = <SpotIssue>[];
    var progress = 0.0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final spots = widget.template.spots;
                for (var i = 0; i < spots.length; i++) {
                  issues.addAll(validateSpot(spots[i], i));
                  progress = (i + 1) / spots.length;
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 1));
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (issues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All spots valid'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in issues)
                  ListTile(
                    title: Text(i.message),
                    onTap: () {
                      Navigator.pop(context);
                      _focusSpot(i.spotId);
                    },
                  ),
              ],
            ),
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



  void _regenerateEv() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
              a.ev = computePushEV(
                heroBbStack: stack,
                bbCount: spot.hand.playerCount - 1,
                heroHand: hand,
              anteBb: widget.template.anteBb,
              );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _regenerateIcm() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
              final chipEv = a.ev ?? computePushEV(
                heroBbStack: stack,
                bbCount: spot.hand.playerCount - 1,
                heroHand: hand,
              anteBb: widget.template.anteBb,
              );
            a.icmEv = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: chipEv,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  void _recalculateAll() {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
              a.ev = computePushEV(
                heroBbStack: stack,
                bbCount: spot.hand.playerCount - 1,
                heroHand: hand,
              anteBb: widget.template.anteBb,
              );
              a.icmEv = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: a.ev!,
            );
            break;
          }
        }
      }
    });
    _persist();
  }

  Future<void> _reEvaluateAll() async {
    _recordSnapshot();
    setState(() {
      for (final spot in widget.template.spots) {
        final hero = spot.hand.heroIndex;
        final hand = handCode(spot.hand.heroCards);
        final stack = spot.hand.stacks['$hero']?.round();
        if (hand == null || stack == null) continue;
        final acts = spot.hand.actions[0] ?? [];
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            final ev = computePushEV(
              heroBbStack: stack,
              bbCount: spot.hand.playerCount - 1,
              heroHand: hand,
              anteBb: widget.template.anteBb,
            );
            final icm = computeIcmPushEV(
              chipStacksBb: stacks,
              heroIndex: hero,
              heroHand: hand,
              chipPushEv: ev,
            );
            a
              ..ev = ev
              ..icmEv = icm;
            final r = spot.evalResult;
            spot.evalResult = EvaluationResult(
              correct: r?.correct ?? true,
              expectedAction: r?.expectedAction ?? 'push',
              userEquity: r?.userEquity ?? 0,
              expectedEquity: r?.expectedEquity ?? 0,
              ev: ev,
              icmEv: icm,
              hint: r?.hint,
            );
            spot.dirty = false;
            break;
          }
        }
      }
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Re-evaluated ${widget.template.spots.length} spots')),
    );
  }

  void _tagAllMistakes() {
    int count = 0;
    setState(() {
      for (final s in widget.template.spots) {
        final r = s.evalResult;
        if (r != null && !r.correct && !s.tags.contains('Mistake')) {
          s.tags.add('Mistake');
          _history.log('Tagged', s.title, s.id);
          count++;
        }
      }
    });
    _persist();
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tagged $count spot(s)')),
      );
    }
  }

  Future<void> _evaluateAllSpots() async {
    setState(() => _evaluatingAll = true);
    final spots = widget.template.spots;
    final total = spots.length;
    int done = 0;
    int errors = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (final spot in spots) {
                  try {
                    final res = await context
                        .read<EvaluationExecutorService>()
                        .evaluate(spot);
                    if (mounted) {
                      setState(() => spot.evalResult = res);
                      await _persist();
                    }
                  } catch (e) {
                    errors++;
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Spot "${spot.title}" failed: $e'),
                        ),
                      );
                    }
                  }
                  done++;
                  if (mounted) setDialog(() {});
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: done / total),
                  const SizedBox(height: 12),
                  Text(
                    'Evaluated $done / $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _evaluatingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Evaluated $total spots (${total - errors} OK, $errors errors)'),
      ),
    );
  }

  Future<void> _generateAllEv() async {
    setState(() => _generatingAll = true);
    final spots = _visibleSpots();
    final total = spots.length;
    int done = 0;
    final failed = <String>[];
    _cancelRequested = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < spots.length; i++) {
                  if (_cancelRequested) break;
                  final s = spots[i];
                  try {
                    if (s.heroEv == null) {
                      await const PushFoldEvService()
                          .evaluate(s, anteBb: widget.template.anteBb);
                      TemplateCoverageUtils.recountAll(widget.template);
                      if (!mounted) return;
                      setState(() {
                        if (_autoSortEv) _sortSpots();
                      });
                    }
                    if (mounted) setState(() {});
                  } catch (_) {
                    failed.add('${i + 1}. ${s.title.isEmpty ? 'Spot' : s.title}');
                  }
                  done++;
                  if (mounted) setDialog(() {});
                  await Future.delayed(Duration.zero);
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total EV…'),
              actions: [
                TextButton(
                  onPressed: () => _cancelRequested = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _generatingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generated $total spots (${total - failed.length} OK, ${failed.length} errors)'),
      ),
    );
    if (failed.isNotEmpty) {
      await _showGenerationErrors(failed, 'EV');
    }
  }

  Future<void> _generateAllIcm() async {
    setState(() => _generatingIcm = true);
    final spots = _visibleSpots();
    final total = spots.length;
    int done = 0;
    final failed = <String>[];
    _cancelRequested = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < spots.length; i++) {
                  if (_cancelRequested) break;
                  final s = spots[i];
                  try {
                    if (s.heroIcmEv == null) {
                      await const PushFoldEvService()
                          .evaluateIcm(s, anteBb: widget.template.anteBb);
                      TemplateCoverageUtils.recountAll(widget.template);
                      if (!mounted) return;
                      setState(() {
                        if (_autoSortEv) _sortSpots();
                      });
                    }
                    if (mounted) setState(() {});
                  } catch (_) {
                    failed.add('${i + 1}. ${s.title.isEmpty ? 'Spot' : s.title}');
                  }
                  done++;
                  if (mounted) setDialog(() {});
                  await Future.delayed(Duration.zero);
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total ICM…'),
              actions: [
                TextButton(
                  onPressed: () => _cancelRequested = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _generatingIcm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generated $total spots (${total - failed.length} OK, ${failed.length} errors)'),
      ),
    );
    if (failed.isNotEmpty) {
      await _showGenerationErrors(failed, 'ICM');
    }
  }

  Future<void> _showGenerationErrors(List<String> failed, String type) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$type Generation Errors (${failed.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: failed.length,
            itemBuilder: (_, i) => ListTile(title: Text(failed[i])),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: failed.join('\n')));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadPreview() async {
    final png = widget.template.png;
    if (png != null) {
      final path = await PreviewCacheService.instance.getPreviewPath(png);
      if (mounted) setState(() => _previewPath = path);
    }
  }

  Future<void> _ensureEval() async {
    final needs = widget.template.spots.any((s) =>
        s.heroEv == null || s.heroIcmEv == null || s.dirty);
    if (!needs) return;
    setState(() => _loadingEval = true);
    await BulkEvaluatorService()
        .generateMissingForTemplate(widget.template, onProgress: null)
        .catchError((_) {});
    TemplateCoverageUtils.recountAll(widget.template);
    if (mounted) setState(() => _loadingEval = false);
  }

  void _maybeStartTraining() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_trainedPromptKey(widget.template.id)) ?? false) return;
    final hasPush =
        widget.template.spots.any((s) => s.tags.contains('push'));
    final hasFold =
        widget.template.spots.any((s) => s.tags.contains('fold'));
    if (!(hasPush && hasFold)) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(l.startTrainingSessionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          )
        ],
      ),
    );
    prefs.setBool(_trainedPromptKey(widget.template.id), true);
    if (ok != true || !mounted) return;
    await context
        .read<TrainingSessionService>()
        .startSession(widget.template, persist: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
    if (!mounted) return;
  }

  Future<void> _calculateMissingEvIcm() async {
    setState(() {
      _calculatingMissing = true;
      _calcProgress = 0;
    });
    int updated = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final res = await BulkEvaluatorService().generateMissing(
                  widget.template,
                  onProgress: (p) {
                    _calcProgress = p;
                    if (mounted) {
                      setDialog(() {});
                      setState(() {});
                    }
                  },
                );
                updated = res.length;
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: _calcProgress),
                  const SizedBox(height: 12),
                  Text(
                    '${(_calcProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() => _calculatingMissing = false);
    if (updated > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Updated $updated spots')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to update')));
    }
  }

  Future<void> _bulkAddTag([List<String>? ids]) async {
    final service = context.read<TemplateStorageService>();
    final allTags = {
      ...service.templates.expand((t) => t.tags),
      ...widget.template.tags,
    }.toList();
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
    final targets = ids ?? _selectedSpotIds.toList();
    if (targets.isEmpty) return;
    _recordSnapshot();
    setState(() {
      for (final id in targets) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        if (!s.tags.contains(tag)) {
          s.tags.add(tag);
          _history.log('Tagged', s.title, s.id);
        }
        s.isNew = false;
      }
      if (ids == null) _selectedSpotIds.clear();
    });
    await _persist();
    if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
      setState(() => _newOnly = false);
      _storeNewOnly();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tagged ${targets.length} spot(s)'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final snap = _history.undo(widget.template.spots);
            if (snap != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(snap);
                if (_autoSortEv) _sortSpots();
              });
              await _persist();
            }
          },
        ),
      ),
    );
  }

  Future<void> _bulkTag() => _bulkAddTag();

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
        if (s.tags.remove(tag)) {
          _history.log('Untagged', s.title, s.id);
        }
      }
    });
    await _persist();
    setState(() => _selectedSpotIds.clear());
  }

  Future<void> _bulkMoveToTag(String tag) async {
    setState(() {
      for (final id in _selectedSpotIds) {
        final s = widget.template.spots.firstWhere((e) => e.id == id);
        s.tags
          .clear();
        if (tag.isNotEmpty) {
          s.tags.add(tag);
          _history.log('Tagged', s.title, s.id);
        } else {
          _history.log('Untagged', s.title, s.id);
        }
      }
    });
    await _persist();
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
    await _persist();
    setState(() {
      _selectedSpotIds.clear();
      if (!newState) {
        _pinnedOnly = false;
        _storePinnedOnly();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newState ? 'Pinned' : 'Unpinned'} ${spots.length} spot(s)')),
    );
  }

  Future<void> _bulkTransfer(bool move, [List<String>? ids]) async {
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
    final spots = [
      for (final s in widget.template.spots)
        if ((ids ?? _selectedSpotIds).contains(s.id)) s
    ];
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
      for (final s in spots) {
        s.isNew = false;
      }
    });
    await _persist();
    if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
      setState(() => _newOnly = false);
      _storeNewOnly();
    }
    if (ids == null) setState(() => _selectedSpotIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${move ? 'Moved' : 'Copied'} ${copies.length} spot(s)')),
    );
  }

  Future<void> _bulkMove() => _bulkTransfer(true);
  Future<void> _bulkCopy() => _bulkTransfer(false);
  Future<void> _bulkDuplicate() async {
    final spots = [
      for (final s in widget.template.spots)
        if (_selectedSpotIds.contains(s.id)) s
    ];
    if (spots.isEmpty) return;
    _recordSnapshot();
    setState(() {
      for (final spot in spots) {
        final i = widget.template.spots.indexOf(spot);
        final copy = spot.copyWith(
          id: const Uuid().v4(),
          editedAt: DateTime.now(),
          hand: HandData.fromJson(spot.hand.toJson()),
          tags: List.from(spot.tags),
        );
        widget.template.spots.insert(i + 1, copy);
      }
      if (_autoSortEv) _sortSpots();
      _selectedSpotIds.clear();
    });
    await _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicated ${spots.length} spot(s)'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final snap = _history.undo(widget.template.spots);
            if (snap != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(snap);
                if (_autoSortEv) _sortSpots();
              });
              await _persist();
            }
          },
        ),
      ),
    );
  }

  Future<void> _recalcSelected() async {
    final spots = [
      for (final s in widget.template.spots)
        if (_selectedSpotIds.contains(s.id)) s
    ];
    if (spots.isEmpty) return;
    setState(() {
      _calculatingMissing = true;
      _calcProgress = 0;
    });
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                var done = 0;
                for (final spot in spots) {
                  await BulkEvaluatorService().generateMissing(
                    spot,
                    anteBb: widget.template.anteBb,
                  );
                  done++;
                  _calcProgress = done / spots.length;
                  if (mounted) {
                    setDialog(() {});
                    setState(() {});
                  }
                }
                await _persist();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: _calcProgress),
                  const SizedBox(height: 12),
                  Text(
                    '${(_calcProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _calculatingMissing = false;
      _selectedSpotIds.clear();
      if (_autoSortEv) _sortSpots();
    });
  }

  Future<void> _newPackFromSelection() async {
    final ctrl = TextEditingController(text: '${widget.template.name} Subset');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Pack'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, ctrl.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
    if (name == null) return;
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
      name: name.isEmpty ? 'New Pack' : name,
      gameType: widget.template.gameType,
      spots: spots,
      createdAt: DateTime.now(),
    );
    final service = context.read<TemplateStorageService>();
    service.addTemplate(tpl);
    final index = widget.templates.indexOf(widget.template);
    setState(() {
      widget.templates.insert(index + 1, tpl);
      _selectedSpotIds.clear();
    });
    await _persist();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: tpl,
          templates: widget.templates,
        ),
      ),
    );
  }

  Future<void> _bulkExport() async {
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
    _recordSnapshot();
    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name:
          '${widget.template.name} – Export ${DateFormat.yMd().format(DateTime.now())}',
      gameType: widget.template.gameType,
      spots: spots,
      createdAt: DateTime.now(),
    );
    final service = context.read<TemplateStorageService>();
    service.addTemplate(tpl);
    final index = widget.templates.indexOf(widget.template);
    setState(() {
      widget.templates.insert(index + 1, tpl);
      _selectedSpotIds.clear();
    });
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${spots.length} spot(s)'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              service.removeTemplate(tpl);
              setState(() => widget.templates.remove(tpl));
              await _persist();
            },
          ),
        ),
      );
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: tpl,
          templates: widget.templates,
        ),
      ),
    );
  }

  Future<void> _makeMistakePack() async {
    final mistakes = widget.template.spots
        .where((s) => s.tags.contains('Mistake'))
        .map((s) => s.copyWith(id: const Uuid().v4()))
        .toList();
    if (mistakes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No mistakes found')));
      return;
    }
    final newTpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${widget.template.name} – Mistakes',
      gameType: widget.template.gameType,
      spots: mistakes,
      createdAt: DateTime.now(),
    );
    final service = context.read<TemplateStorageService>();
    service.addTemplate(newTpl);
    widget.templates.add(newTpl);
    await TrainingPackStorage.save(widget.templates);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: newTpl,
          templates: widget.templates,
        ),
      ),
    );
  }


  Future<void> _startTrainingSession() async {
    await context
        .read<TrainingSessionService>()
        .startSession(widget.template, persist: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Future<void> _addToLibrary() async {
    final list = await TrainingPackStorage.load();
    list.add(widget.template);
    await TrainingPackStorage.save(list);
    context.read<TemplateStorageService>().addTemplate(widget.template);
    if (mounted) Navigator.pop(context);
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
      _recordSnapshot();
      _lastRemoved = widget.template.spots.where((s) => _selectedSpotIds.contains(s.id)).toList();
      for (final s in _lastRemoved!) {
        s.isNew = false;
      }
      setState(() {
        widget.template.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        _selectedSpotIds.clear();
        if (_autoSortEv) _sortSpots();
      });
      _persist();
      if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
        setState(() => _newOnly = false);
        _storeNewOnly();
      }
      setState(() =>
          _history.log('Deleted', '${_lastRemoved!.length} spots', ''));
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
              _persist();
            },
          ),
        ),
      );
    }
  }

  Future<void> _bulkDeleteQuick() async {
    final ids = _selectedSpotIds.toSet();
    if (ids.isEmpty) return;
    _recordSnapshot();
    setState(() {
      widget.template.spots.removeWhere((s) => ids.contains(s.id));
      _selectedSpotIds.clear();
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${ids.length} spot(s)'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final snap = _history.undo(widget.template.spots);
            if (snap != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(snap);
                if (_autoSortEv) _sortSpots();
              });
              await _persist();
            }
          },
        ),
      ),
    );
  }

  void _toggleSelectAll() {
    final allIds = {for (final s in widget.template.spots) s.id};
    setState(() {
      if (_selectedSpotIds.length == allIds.length) {
        _selectedSpotIds.clear();
      } else {
        _selectedSpotIds
          ..clear()
          ..addAll(allIds);
      }
    });
    _maybeShowMultiTip();
  }

  void _selectAllNew() {
    setState(() {
      _selectedSpotIds
        ..clear()
        ..addAll([
          for (final s in widget.template.spots)
            if (s.isNew) s.id
        ]);
    });
    _maybeShowMultiTip();
  }

  void _selectAllDuplicates() {
    final dups = _duplicateSpotGroups().expand((g) => g.skip(1));
    setState(() {
      _selectedSpotIds
        ..clear()
        ..addAll([for (final i in dups) widget.template.spots[i].id]);
    });
    _maybeShowMultiTip();
  }

  void _invertSelection() {
    final all = widget.template.spots.map((e) => e.id).toSet();
    setState(() => _selectedSpotIds = all.difference(_selectedSpotIds));
    _maybeShowMultiTip();
  }

  bool _onKey(FocusNode _, RawKeyEvent e) {
    if (e is! RawKeyDownEvent) return false;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyP && e.isAltPressed) {
      setState(() {
        _pinnedOnly = !_pinnedOnly;
        _storePinnedOnly();
      });
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyN && e.isAltPressed) {
      setState(() {
        _newOnly = !_newOnly;
        _storeNewOnly();
      });
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyD && e.isAltPressed) {
      setState(() {
        _duplicatesOnly = !_duplicatesOnly;
        _storeDupOnly();
      });
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyS && e.isAltPressed) {
      _toggleSortMode();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyV && e.isAltPressed) {
      _importFromClipboardSpots();
      return true;
    }
    final isCmd = e.isControlPressed || e.isMetaPressed;
    if (!isCmd) return false;
    if (e.logicalKey == LogicalKeyboardKey.keyA) {
      _toggleSelectAll();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyI) {
      _invertSelection();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyS && e.isShiftPressed) {
      _selectAllDuplicates();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyD && e.isShiftPressed) {
      setState(() => _showDupHint = false);
      _findDuplicateSpots();
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyV) {
      _validateAllSpots();
      return true;
    }
    return false;
  }

  PreferredSizeWidget _bulkBar() {
    final n = _selectedSpotIds.length;
    if (n == 0) return const SizedBox.shrink();
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.grey[900],
      title: Text('$n selected'),
      actions: const [
        IconButton(icon: Icon(Icons.delete), tooltip: 'Delete', onPressed: _bulkDeleteQuick),
        IconButton(icon: Icon(Icons.copy_all), tooltip: 'Duplicate', onPressed: _bulkDuplicate),
        IconButton(icon: Icon(Icons.label), tooltip: 'Tag', onPressed: _bulkTag),
        IconButton(icon: Icon(Icons.open_in_new), tooltip: 'Export to Pack', onPressed: _bulkExport),
      ],
    );
  }

  void _duplicateSpot(TrainingPackSpot spot) {
    _recordSnapshot();
    final i = widget.template.spots.indexOf(spot);
    if (i == -1) return;
    final copy = spot.copyWith(
      id: const Uuid().v4(),
      editedAt: DateTime.now(),
      hand: HandData.fromJson(spot.hand.toJson()),
      tags: List.from(spot.tags),
    );
    setState(() => widget.template.spots.insert(i + 1, copy));
    _persist();
    setState(() => _log('Added', copy));
  }

  /// Универсальное меню для карточки спота
  Widget _buildSpotMenu(TrainingPackSpot spot) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (v) {
        switch (v) {
          case 'pin':
            setState(() {
              spot.pinned = !spot.pinned;
              if (_autoSortEv) _sortSpots();
            });
            _persist();
            break;
          case 'copy':
            _copiedSpot = spot.copyWith(
              id: const Uuid().v4(),
              editedAt: DateTime.now(),
              hand: HandData.fromJson(spot.hand.toJson()),
              tags: List.from(spot.tags),
            );
            break;
          case 'paste':
            if (_copiedSpot != null) {
              final i = widget.template.spots.indexOf(spot);
              final s = _copiedSpot!.copyWith(
                id: const Uuid().v4(),
                editedAt: DateTime.now(),
                hand: HandData.fromJson(_copiedSpot!.hand.toJson()),
                tags: List.from(_copiedSpot!.tags),
              );
              setState(() => widget.template.spots.insert(i + 1, s));
              _persist();
            }
            break;
          case 'dup':
            _duplicateSpot(spot);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pin',
          child: Text(spot.pinned ? '📌 Unpin' : '📌 Pin'),
        ),
        const PopupMenuItem(value: 'copy',  child: Text('📋 Copy')),
        if (_copiedSpot != null)
          const PopupMenuItem(value: 'paste', child: Text('📥 Paste')),
        const PopupMenuItem(value: 'dup',   child: Text('📄 Duplicate')),
      ],
    );
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
    await _persist();
    setState(() {});
  }

  Future<void> _manageTags() async {
    final tags = <String>{
      ...widget.template.tags,
      ...widget.template.spots.expand((s) => s.tags),
    }.toList()
      ..sort((a, b) => a.compareTo(b));
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          void rename(String oldTag, String newTag) {
            if (newTag.isEmpty || oldTag == newTag) return;
            setState(() {
              for (final s in widget.template.spots) {
                for (var i = 0; i < s.tags.length; i++) {
                  if (s.tags[i] == oldTag) s.tags[i] = newTag;
                }
                s.tags = s.tags.toSet().toList();
              }
              widget.template.tags.removeWhere((t) => t == oldTag);
              if (!widget.template.tags.contains(newTag)) {
                widget.template.tags.add(newTag);
              }
            });
            _persist();
            setStateDialog(() {
              final i = tags.indexOf(oldTag);
              if (i != -1) tags[i] = newTag;
            });
          }

          void remove(String tag) {
            setState(() {
              widget.template.tags.removeWhere((t) => t == tag);
              for (final s in widget.template.spots) {
                s.tags.removeWhere((t) => t == tag);
              }
            });
            _persist();
            setStateDialog(() => tags.remove(tag));
          }

          return AlertDialog(
            title: const Text('Manage Tags'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tag in tags)
                    _ManageTagTile(
                      key: ValueKey(tag),
                      tag: tag,
                      onRename: (v) => rename(tag, v),
                      onDelete: () => remove(tag),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }


  List<List<int>> _duplicateSpotGroups() =>
      duplicateSpotGroupsStatic(widget.template.spots);

  bool _isDup(TrainingPackSpot s) {
    final index = widget.template.spots.indexOf(s);
    if (index == -1) return false;
    for (final g in _duplicateSpotGroups()) {
      if (g.skip(1).contains(index)) return true;
    }
    return false;
  }

  bool _importDuplicateGroups(List<TrainingPackSpot> imported) {
    final before = _pasteUndo ?? [];
    final existing = <String>{};
    for (final s in before) {
      final h = s.hand;
      final hero = h.heroCards.replaceAll(' ', '');
      final board = h.board.join();
      existing.add('${h.position.name}-$hero-$board');
    }
    for (final s in imported) {
      final h = s.hand;
      final hero = h.heroCards.replaceAll(' ', '');
      final board = h.board.join();
      final key = '${h.position.name}-$hero-$board';
      if (existing.contains(key)) return true;
      existing.add('$key-${s.editedAt.millisecondsSinceEpoch}-${s.id}');
    }
    return false;
  }

  String _duplicateSpotTitle(int i) {
    final h = widget.template.spots[i].hand;
    final hero = h.heroCards;
    final board = h.board.join(' ');
    return '${h.position.label} $hero – $board';
  }

  void _deleteDuplicateSpotGroups(List<List<int>> groups) {
    _recordSnapshot();
    final removed = <(TrainingPackSpot, int)>[];
    for (final g in groups) {
      for (final i in g) {
        widget.template.spots[i].isNew = false;
      }
    }
    setState(() {
      for (final g in groups) {
        for (final i in g.skip(1).toList().reversed) {
          final s = widget.template.spots.removeAt(i);
          removed.add((s, i));
        }
      }
      if (_autoSortEv) _sortSpots();
      _showDupHint = false;
    });
    if (_duplicatesOnly) _duplicatesOnly = false;
    _persist();
    setState(() => _selectedSpotIds.clear());
    setState(() => _history.log('Deleted', '${removed.length} spots', ''));
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${removed.length} spots'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in removed.reversed) {
                widget.template.spots.insert(
                    r.$2.clamp(0, widget.template.spots.length), r.$1);
              }
              if (_autoSortEv) _sortSpots();
            });
            _persist();
          },
        ),
      ),
    );
  }

  void _mergeDuplicateSpotGroups(List<List<int>> groups) {
    _recordSnapshot();
    final removed = <(TrainingPackSpot, int)>[];
    for (final g in groups) {
      for (final i in g) {
        widget.template.spots[i].isNew = false;
      }
    }
    setState(() {
      for (final g in groups) {
        final baseIndex = g.first;
        var base = widget.template.spots[baseIndex];
        final tags = {...base.tags};
        String note = base.note;
        bool pinned = base.pinned;
        for (final i in g.skip(1)) {
          final s = widget.template.spots[i];
          tags.addAll(s.tags);
          if (s.note.isNotEmpty) {
            if (note.isNotEmpty) note += '\n';
            note += s.note;
          }
          if (s.pinned) pinned = true;
          removed.add((s, i));
        }
        base = base.copyWith(tags: tags.toList(), note: note, pinned: pinned);
        widget.template.spots[baseIndex] = base;
        for (final i in g.skip(1).toList().reversed) {
          widget.template.spots.removeAt(i);
        }
      }
      if (_autoSortEv) _sortSpots();
      _showDupHint = false;
    });
    if (_duplicatesOnly) _duplicatesOnly = false;
    _persist();
    setState(() => _selectedSpotIds.clear());
    setState(() => _history.log('Deleted', '${removed.length} spots', ''));
    if (removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Merged ${removed.length} spots'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (final r in removed.reversed) {
                widget.template.spots.insert(
                    r.$2.clamp(0, widget.template.spots.length), r.$1);
              }
              if (_autoSortEv) _sortSpots();
            });
            _persist();
          },
        ),
      ),
    );
  }

  Future<void> _findDuplicateSpots() async {
    final groups = _duplicateSpotGroups();
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No duplicates')));
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Duplicates (${groups.length})',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final g in groups)
                ListTile(
                  title: Text(
                    _duplicateSpotTitle(g.first),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    g.map((i) => widget.template.spots[i].title).join(', '),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'delete') {
      _deleteDuplicateSpotGroups(groups);
    } else if (result == 'merge') {
      _mergeDuplicateSpotGroups(groups);
    }
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
    if (_evAsc) {
      others.sort((a, b) => _spotEv(a).compareTo(_spotEv(b)));
    } else {
      others.sort((a, b) => _spotEv(b).compareTo(_spotEv(a)));
    }
    widget.template.spots
      ..clear()
      ..addAll(pinned)
      ..addAll(others);
  }

  Future<void> _toggleEvSort() async {
    setState(() {
      _evAsc = !_evAsc;
      _sortSpots();
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_prefsSortModeKey, _evAsc ? 'asc' : 'desc');
  }

  void _toggleSortMode() {
    setState(() {
      _sortMode = _sortMode == SortMode.chronological
          ? SortMode.position
          : SortMode.chronological;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _sortMode == SortMode.position
              ? 'Sorted by position'
              : 'Sorted by date added',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _storeSortMode();
  }

  void _showFilters() {
    final tags = widget.template.spots.expand((s) => s.tags).toSet();
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Pinned Only'),
                value: _pinnedOnly,
                onChanged: (v) => set(() {
                  this.setState(() => _pinnedOnly = v);
                  _storePinnedOnly();
                }),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in tags)
                    FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (v) => set(() {
                        this.setState(() {
                          v ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                        });
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _evFilter,
                decoration: const InputDecoration(labelText: 'EV'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'ok', child: Text('OK')),
                  DropdownMenuItem(value: 'error', child: Text('Errors')),
                  DropdownMenuItem(value: 'empty', child: Text('Empty')),
                ],
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  final val = v ?? 'all';
                  set(() => _evFilter = val);
                  this.setState(() {});
                  prefs.setString(_prefsEvFilterKey, val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _priorityFilter,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (int i = 1; i <= 5; i++)
                    DropdownMenuItem(value: i, child: Text('$i')),
                ],
                onChanged: (v) async {
                  set(() => _priorityFilter = v);
                  this.setState(() {});
                  _storePriorityFilter();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTemplateSettings() async {
    final heroCtr = TextEditingController(text: widget.template.heroBbStack.toString());
    final stacks = [
      for (var i = 0; i < 9; i++)
        if (i < widget.template.playerStacksBb.length)
          widget.template.playerStacksBb[i]
        else
          0
    ];
    final stackCtrs = [
      for (var i = 0; i < 9; i++)
        TextEditingController(text: stacks[i].toString())
    ];
    HeroPosition pos = widget.template.heroPos;
    final countCtr = TextEditingController(text: widget.template.spotCount.toString());
    double bbCall = widget.template.bbCallPct.toDouble();
    final anteCtr = TextEditingController(text: widget.template.anteBb.toString());
    String rangeStr = widget.template.heroRange?.join(' ') ?? '';
    String rangeMode = 'simple';
    final rangeCtr = TextEditingController(text: rangeStr);
    bool rangeErr = false;
    final eval = EvaluationSettingsService.instance;
    final thresholdCtr =
        TextEditingController(text: eval.evThreshold.toStringAsFixed(2));
    final endpointCtr = TextEditingController(text: eval.remoteEndpoint);
    bool icm = eval.useIcm;
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, set) {
            final narrow = MediaQuery.of(context).size.width < 500;
            final fields = [
                TextFormField(
                  controller: heroCtr,
                  decoration: const InputDecoration(labelText: 'Hero BB Stack'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? '≥ 1' : null,
                ),
              DropdownButtonFormField<HeroPosition>(
                value: pos,
                decoration: const InputDecoration(labelText: 'Hero Position'),
                items: const [
                  DropdownMenuItem(value: HeroPosition.sb, child: Text('SB')),
                  DropdownMenuItem(value: HeroPosition.bb, child: Text('BB')),
                  DropdownMenuItem(value: HeroPosition.btn, child: Text('BTN')),
                  DropdownMenuItem(value: HeroPosition.co, child: Text('CO')),
                  DropdownMenuItem(value: HeroPosition.mp, child: Text('MP')),
                  DropdownMenuItem(value: HeroPosition.utg, child: Text('UTG')),
                ],
                onChanged: (v) => set(() => pos = v ?? HeroPosition.sb),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Player Stacks (BB)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < stackCtrs.length; i++)
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: stackCtrs[i],
                            decoration: InputDecoration(labelText: '#$i'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (int.tryParse(v ?? '') ?? -1) < 0 ? '≥ 0' : null,
                            onChanged: (v) async {
                              final val = int.tryParse(v) ?? 0;
                              set(() {
                                while (widget.template.playerStacksBb.length <
                                    stackCtrs.length) {
                                  widget.template.playerStacksBb.add(0);
                                }
                                widget.template.playerStacksBb[i] = val;
                              });
                              await _persist();
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              TextFormField(
                controller: countCtr,
                decoration: const InputDecoration(labelText: 'Spot Count'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? 0;
                  return n < 1 || n > 169 ? '' : null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BB call ${bbCall.round()}%'),
                  Slider(
                    value: bbCall,
                    min: 0,
                    max: 100,
                    onChanged: (v) => set(() => bbCall = v),
                  ),
                ],
              ),
              TextFormField(
                controller: anteCtr,
                decoration: const InputDecoration(labelText: 'Ante (BB)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? -1;
                  return n < 0 || n > 5 ? '' : null;
                },
              ),
              TextFormField(
                controller: thresholdCtr,
                decoration: const InputDecoration(labelText: 'EV Threshold'),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                onChanged: (v) => set(() {
                  final val = double.tryParse(v) ?? eval.evThreshold;
                  eval.update(threshold: val);
                  this.setState(() {});
                }),
              ),
              SwitchListTile(
                title: const Text('ICM mode'),
                value: icm,
                onChanged: (v) => set(() {
                  icm = v;
                  eval.update(icm: v);
                  this.setState(() {});
                }),
              ),
              TextFormField(
                controller: endpointCtr,
                decoration:
                    const InputDecoration(labelText: 'EV API Endpoint'),
                onChanged: (v) => set(() {
                  eval.update(endpoint: v);
                  this.setState(() {});
                }),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: rangeMode,
                    items: const [
                      DropdownMenuItem(value: 'simple', child: Text('Simple')),
                      DropdownMenuItem(value: 'matrix', child: Text('Matrix')),
                    ],
                    onChanged: (v) => set(() => rangeMode = v ?? 'simple'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: rangeMode == 'simple'
                        ? TextFormField(
                            controller: rangeCtr,
                            decoration: InputDecoration(
                              labelText: 'Hero Range',
                              errorText: rangeErr ? '' : null,
                            ),
                            onChanged: (v) => set(() {
                              rangeStr = v;
                              rangeErr = v.trim().isNotEmpty &&
                                  PackGeneratorService.parseRangeString(v).isEmpty;
                            }),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final init = PackGeneratorService
                                  .parseRangeString(rangeStr)
                                  .toSet();
                              final res = await Navigator.push<Set<String>>(
                                context,
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => MatrixPickerPage(initial: init),
                                ),
                              );
                              if (res != null) {
                                set(() {
                                rangeStr = PackGeneratorService.serializeRange(res);
                                rangeCtr.text = rangeStr;
                                rangeErr = rangeStr.trim().isNotEmpty &&
                                    PackGeneratorService.parseRangeString(rangeStr).isEmpty;
                              });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hero Range',
                                errorText: rangeErr ? '' : null,
                              ),
                              child: Text(
                                rangeStr.isEmpty ? 'All hands' : rangeStr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('PNG with JSON'),
                value: _previewJsonPng,
                onChanged: (v) => set(() {
                  this.setState(() => _previewJsonPng = v);
                  _storePreviewJsonPng();
                }),
              ),
            ];
            final content = narrow
                ? Column(mainAxisSize: MainAxisSize.min, children: fields)
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [for (final f in fields) SizedBox(width: 250, child: f)],
                  );
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fix errors')));
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (ok == true) {
      final hero = int.parse(heroCtr.text.trim());
      final list = [
        for (final c in stackCtrs)
          int.tryParse(c.text.trim()) ?? 0
      ];
      final count = int.parse(countCtr.text.trim());
      int ante = int.parse(anteCtr.text.trim());
      if (ante < 0) ante = 0;
      if (ante > 5) ante = 5;
      final parsedSet = PackGeneratorService.parseRangeString(rangeStr);
      setState(() {
        widget.template.heroBbStack = hero;
        widget.template.playerStacksBb = list;
        widget.template.heroPos = pos;
        widget.template.spotCount = count;
        widget.template.bbCallPct = bbCall.round();
        widget.template.anteBb = ante;
        widget.template.heroRange =
            parsedSet.isEmpty ? null : parsedSet.toList();
      });
      _markAllDirty();
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Template settings updated')));
      }
    }
    heroCtr.dispose();
    for (final c in stackCtrs) {
      c.dispose();
    }
    countCtr.dispose();
    anteCtr.dispose();
    rangeCtr.dispose();
    thresholdCtr.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEval) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final narrow = MediaQuery.of(context).size.width < 400;
    final hasSpots = widget.template.spots.isNotEmpty;
    final variants = widget.template.playableVariants();
    final showExample = !hasSpots && variants.length == 1;
    const posLabels = ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'];
    final shown = _visibleSpots();
    final chipVals = [for (final s in shown) if (s.heroEv != null) s.heroEv!];
    final icmVals = [for (final s in shown) if (s.heroIcmEv != null) s.heroIcmEv!];
    final total = widget.template.spots.length;
    final evTotal = total == 0 ? 0.0 : widget.template.evCovered / total;
    final icmTotal = total == 0 ? 0.0 : widget.template.icmCovered / total;
    final primaryColor = Theme.of(context).primaryColor;
    final totalSpots = shown.length;
    final mistakeCount =
        widget.template.spots.where((s) => s.tags.contains('Mistake')).length;
    final mistakeFree =
        shown.where((s) => !s.tags.contains('Mistake')).length;
    final mistakePct = totalSpots == 0 ? 0 : mistakeFree / totalSpots;
    final evCovered = shown.where((s) => s.heroEv != null && !s.dirty).length;
    final icmCovered = shown.where((s) => s.heroIcmEv != null && !s.dirty).length;
    final evCoverage = totalSpots == 0 ? 0.0 : evCovered / totalSpots;
    final icmCoverage = totalSpots == 0 ? 0.0 : icmCovered / totalSpots;
    final coverageWarningNeeded = evCoverage < 0.8 || icmCoverage < 0.8;
    final bothCoverage = evCoverage < icmCoverage ? evCoverage : icmCoverage;
    final heroEvsAll = [
      for (final s in shown)
        if (s.heroEv != null && !s.dirty) s.heroEv!
    ];
    final inLibrary = context
        .watch<TemplateStorageService>()
        .templates
        .any((t) => t.id == widget.template.id);
    final canAddToLibrary = _originPreset != null && !inLibrary;
    final avgEv = heroEvsAll.isEmpty
        ? null
        : heroEvsAll.reduce((a, b) => a + b) / heroEvsAll.length;
    final mistakesVisible =
        shown.where((s) => s.tags.contains('Mistake')).length;
    final tagCounts = <String, int>{};
    for (final t in shown.expand((s) => s.tags)) {
      tagCounts[t] = (tagCounts[t] ?? 0) + 1;
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summaryTags = [for (final e in topTags.take(3)) e.key];
    final handCounts = _handTypeCounts();
    final handTotals = _handTypeTotals();
    final focusAvg = averageFocusCoverage(handCounts, handTotals);
    final historyGroups = <String, List<ChangeEntry>>{};
    for (final e in _history.history) {
      final day = DateFormat.yMd().format(e.time);
      historyGroups.putIfAbsent(day, () => []).add(e);
    }
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
    if (_spotSort != SpotSort.original) {
      final pinned = [for (final s in sorted) if (s.pinned) s];
      final rest = [for (final s in sorted) if (!s.pinned) s];
      int Function(TrainingPackSpot, TrainingPackSpot) cmp;
      switch (_spotSort) {
        case SpotSort.evDesc:
          cmp = (a, b) =>
              (b.heroEv ?? double.negativeInfinity).compareTo(a.heroEv ?? double.negativeInfinity);
          break;
        case SpotSort.evAsc:
          cmp = (a, b) =>
              (a.heroEv ?? double.infinity).compareTo(b.heroEv ?? double.infinity);
          break;
        case SpotSort.icmDesc:
          cmp = (a, b) => (b.heroIcmEv ?? double.negativeInfinity)
              .compareTo(a.heroIcmEv ?? double.negativeInfinity);
          break;
        case SpotSort.icmAsc:
          cmp = (a, b) =>
              (a.heroIcmEv ?? double.infinity).compareTo(b.heroIcmEv ?? double.infinity);
          break;
        default:
          cmp = (a, b) => 0;
      }
      rest.sort(cmp);
      sorted = [...pinned, ...rest];
    }
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const DeleteBulkIntent(),
        LogicalKeySet(LogicalKeyboardKey.backspace): const DeleteBulkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): const DuplicateBulkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT): const TagBulkIntent(),
      },
      child: Actions(
        actions: {
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _undo()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => _redo()),
          DeleteBulkIntent: CallbackAction(onInvoke: (_) => _selectedSpotIds.isEmpty ? null : _bulkDeleteQuick()),
          DuplicateBulkIntent: CallbackAction(onInvoke: (_) => _selectedSpotIds.isEmpty ? null : _bulkDuplicate()),
          TagBulkIntent: CallbackAction(onInvoke: (_) => _selectedSpotIds.isEmpty ? null : _bulkTag()),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          onKey: (n, e) => _onKey(n, e)
              ? KeyEventResult.handled
              : KeyEventResult.ignored,
          child: Scaffold(

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + (_isMultiSelect ? kToolbarHeight : 0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isMultiSelect) _bulkBar(),
            AppBar(
        leading: _isMultiSelect
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedSpotIds.clear()),
              )
            : null,
        title: _isMultiSelect
            ? Text('${_selectedSpotIds.length} selected')
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.readOnly)
                              Text(_templateName)
                            else
                              GestureDetector(
                                onTap: _renameTemplate,
                                child: Text(_templateName),
                              ),
                            const SizedBox(width: 8),
                            Builder(builder: (_) {
                              final int evPct = (evCoverage * 100).round();
                              final int icmPct = (icmCoverage * 100).round();
                              Color colorFor(int p) {
                                if (p < 70) return Colors.red;
                                if (p < 90) return Colors.amber;
                                return Colors.green;
                              }
                              return Row(
                                children: [
                                  Chip(
                                    label: Text('EV $evPct%',
                                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: colorFor(evPct),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text('ICM $icmPct%',
                                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: colorFor(icmPct),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        Builder(builder: (context) {
                          final total = widget.template.spots.length;
                          final ev = widget.template.evCovered;
                          final icm = widget.template.icmCovered;
                          final evPct = total == 0 ? 0 : (ev * 100 / total).round();
                          final icmPct = total == 0 ? 0 : (icm * 100 / total).round();
                          Color avgColor(double v) {
                            if (v >= 0.5) return Colors.green;
                            if (v <= -0.5) return Colors.red;
                            return Colors.yellow;
                          }
                          return Row(
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: '$evPct% EV',
                                  children: [
                                    const TextSpan(text: ' • '),
                                    TextSpan(text: '$icmPct% ICM'),
                                  ],
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              if (avgEv != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${avgEv >= 0 ? '+' : ''}${avgEv.toStringAsFixed(2)} BB',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: avgColor(avgEv)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('Mistakes $mistakesVisible/${shown.length}',
                                    style: const TextStyle(fontSize: 12, color: Colors.white)),
                                backgroundColor: mistakesVisible > 0
                                    ? Colors.redAccent
                                    : Colors.grey,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  Builder(builder: (_) {
                    final missing =
                        BulkEvaluatorService().countMissing(widget.template);
                    return Row(
                      children: [
                        Text(
                          '${_visibleSpotsCount()} spots',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$missing missing',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Missing only'),
                          selected: _showMissingOnly,
                          onSelected: (_) =>
                              setState(() => _showMissingOnly = !_showMissingOnly),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Mistakes'),
                          selected: _filterMistakes,
                          onSelected: (_) =>
                              setState(() => _filterMistakes = !_filterMistakes),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Mistakes ↑'),
                          selected: _mistakeFirst,
                          onSelected: (_) =>
                              setState(() => _mistakeFirst = !_mistakeFirst),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(_sortEvAsc ? 'Manual ↺' : 'Sort EV ↑'),
                          selected: _sortEvAsc,
                          onSelected: (_) =>
                              setState(() => _sortEvAsc = !_sortEvAsc),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int?>(
                          value: _priorityFilter,
                          hint: const Text('Priority', style: TextStyle(color: Colors.white70)),
                          dropdownColor: AppColors.cardBackground,
                          style: const TextStyle(color: Colors.white),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All')),
                            for (int i = 1; i <= 5; i++)
                              DropdownMenuItem(value: i, child: Text('$i')),
                          ],
                          onChanged: (v) {
                            setState(() => _priorityFilter = v);
                            _storePriorityFilter();
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
        actions: widget.readOnly
            ? [
                const IconButton(
                    onPressed: _startTrainingSession,
                    icon: Text('Start Training')),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
              ]
            : [
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
              _persist();
            },
          ),
          IconButton(icon: const Text('↶'), onPressed: _canUndo ? _undo : null),
          IconButton(icon: const Text('↷'), onPressed: _canRedo ? _redo : null),
          const IconButton(
            icon: Text('🔄'),
            tooltip: 'Jump to last change',
            onPressed: _jumpToLastChange,
          ),
          const IconButton(
            icon: Icon(Icons.bookmark_add),
            tooltip: 'Save Snapshot',
            onPressed: _saveSnapshotAction,
          ),
          const IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Snapshots',
            onPressed: _showSnapshots,
          ),
          if (_showPasteBubble &&
              widget.template.spots.any((s) => s.isNew))
            const TextButton(onPressed: _undoImport, child: Text('Undo Import')),
          IconButton(
            icon: Icon(_evAsc ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: 'Sort by EV',
            onPressed: _toggleEvSort,
          ),
          IconButton(
            icon: Icon(Icons.sort,
                color:
                    _sortMode == SortMode.chronological ? AppColors.accent : null),
            tooltip: 'Sort Mode',
            onPressed: _toggleSortMode,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Quick Filter',
            onSelected: (v) {
              setState(() => _quickFilter = _quickFilter == v ? null : v);
              _storeQuickFilter();
            },
            itemBuilder: (_) => [
              for (final f in _quickFilters)
                CheckedPopupMenuItem(value: f, checked: _quickFilter == f, child: Text(f)),
            ],
          ),
          if (widget.template.spots.any((s) => !s.isNew && _isDup(s)))
            const TextButton(
              onPressed: _selectAllDuplicates,
              child: Text('Select Duplicates'),
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
            const IconButton(
              icon: Icon(Icons.copy_all),
              tooltip: 'New Pack',
              onPressed: _newPackFromSelection,
            ),
          if (_isMultiSelect)
            const IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete (Ctrl + Backspace)',
              onPressed: _bulkDelete,
            ),
          if (_isMultiSelect)
            const IconButton(
              icon: Icon(Icons.auto_fix_high),
              tooltip: 'Recalc EV/ICM',
              onPressed: _recalcSelected,
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
                _storeSort();
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
          const IconButton(
            icon: Text('🏷️'),
            tooltip: 'Manage Tags',
            onPressed: _manageTags,
          ),
          const IconButton(
            icon: Text('🧹'),
            tooltip: 'Clear Tags',
            onPressed: _clearTags,
          ),
          const IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Clear All Spots',
            onPressed: _clearAll,
          ),
          const IconButton(icon: Text('📋 Paste Spot'), onPressed: _pasteSpot),
          const IconButton(icon: Text('📥 Paste Hand'), onPressed: _pasteHandHistory),
          const IconButton(icon: Icon(Icons.upload), onPressed: _import),
          const IconButton(icon: Icon(Icons.download), onPressed: _export),
          Badge.count(
            count: mistakeCount,
            isLabelVisible: mistakeCount > 0,
            child: IconButton(
              icon: const Text('📂 Preview Bundle'),
              onPressed: _exportingBundle ? null : _previewBundle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _exportingBundle ? null : _exportPackBundle,
          ),
          IconButton(
            icon: const Text('📤 Share'),
            onPressed: _exportingBundle ? null : _shareBundle,
          ),
          IconButton(
            icon: const Text('🖼️'),
            tooltip: 'Export PNG Preview',
            onPressed: _exportingPreview ? null : _exportPreview,
          ),
          const IconButton(icon: Icon(Icons.info_outline), onPressed: _showSummary),
          const IconButton(icon: Text('🚦 Validate'), onPressed: _validateTemplate),
          const IconButton(icon: Text('✅ All'), tooltip: 'Validate All', onPressed: _validateAllSpots),
          IconButton(
            icon: Icon(Icons.push_pin, color: _pinnedOnly ? AppColors.accent : null),
            tooltip: 'Pinned Only',
            onPressed: () {
              setState(() => _pinnedOnly = !_pinnedOnly);
              _storePinnedOnly();
            },
          ),
          IconButton(
            icon: Icon(Icons.fiber_new, color: _newOnly ? AppColors.accent : null),
            tooltip: 'New Only',
            onPressed: () {
              setState(() => _newOnly = !_newOnly);
              _storeNewOnly();
            },
          ),
          IconButton(
            icon: Icon(Icons.error_outline,
                color: _quickFilter == 'Mistake spots' ? AppColors.accent : null),
            tooltip: 'Mistakes Only',
            onPressed: () {
              setState(() => _quickFilter = _quickFilter == 'Mistake spots'
                  ? null
                  : 'Mistake spots');
              _storeQuickFilter();
            },
          ),
          const IconButton(
            icon: Icon(Icons.copy_all),
            tooltip: 'Find Duplicates',
            onPressed: _findDuplicateSpots,
          ),
          IconButton(
            icon: Icon(Icons.copy_all,
                color: _duplicatesOnly ? AppColors.accent : null),
            tooltip: 'Duplicates Only',
            onPressed: () {
              setState(() => _duplicatesOnly = !_duplicatesOnly);
              _storeDupOnly();
            },
          ),
          const IconButton(icon: Text('⚙️ Settings'), onPressed: _showTemplateSettings),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'regenEv') _regenerateEv();
              if (v == 'regenIcm') _regenerateIcm();
              if (v == 'reEval') _reEvaluateAll();
              if (v == 'exportCsv') _exportCsv();
              if (v == 'tagMistakes') _tagAllMistakes();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, set) => SwitchListTile(
                    title: const Text('Offline Mode'),
                    value: OfflineEvaluatorService.isOffline,
                    onChanged: (v) => set(() => OfflineEvaluatorService.isOffline = v),
                  ),
                ),
              ),
              const PopupMenuItem(value: 'regenEv', child: Text('Regenerate EV')),
              const PopupMenuItem(value: 'regenIcm', child: Text('Regenerate ICM')),
              const PopupMenuItem(value: 'reEval', child: Text('Re-evaluate All')),
              const PopupMenuItem(value: 'exportCsv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'tagMistakes', child: Text('Tag All Mistakes')),
            ],
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: IconButton(
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
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: IconButton(
              icon: Icon(
                  _previewMode ? Icons.edit : Icons.remove_red_eye_outlined),
              tooltip: 'Preview Mode',
              onPressed: () {
                setState(() => _previewMode = !_previewMode);
                _storePreview();
              },
          ),
        ),
        const IconButton(
          icon: Icon(Icons.bug_report),
          tooltip: 'Make Mistake Pack',
          onPressed: _makeMistakePack,
        ),
        const IconButton(icon: Icon(Icons.save), onPressed: _save),
        const IconButton(icon: Icon(Icons.description), onPressed: _showMarkdownPreview),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                final file =
                    await PackExportService.exportToPdf(widget.template);
                if (!mounted) return;
                await FileSaverService.instance.sharePdf(file.path);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('PDF exported')));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
          ),
          const IconButton(
              onPressed: _startTrainingSession,
              icon: Text('Start Training'))
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🟡 New, 🔵 Edited', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: const Icon(Icons.search),
                    fillColor: _tagFilter == null ? null : Colors.yellow[50],
                filled: _tagFilter != null,
                suffixIcon: _tagFilter != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _tagFilter = null);
                          _storeTagFilter();
                        },
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in posLabels) ...[
                        FilterChip(
                          label: Text(label),
                          selected: _positionFilter == label,
                          onSelected: (_) => setState(() => _positionFilter = _positionFilter == label ? null : label),
                        ),
                        const SizedBox(width: 8),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : hasSpots && !_isMultiSelect
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showPasteBubble) ...[
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'tmplPasteBubble',
                        mini: true,
                        onPressed: _importFromClipboardSpots,
                        label: Text('Paste Hands'),
                      ),
                      SizedBox(width: 8),
                  IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: _clearClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (_showDupHint) ...[
                  FloatingActionButton.extended(
                    heroTag: 'dupHint',
                    mini: true,
                    backgroundColor: Colors.amber,
                    onPressed: () {
                      setState(() => _showDupHint = false);
                      _findDuplicateSpots();
                    },
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Duplicates found'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (narrow)
                  const FloatingActionButton(
                    heroTag: 'filterSpotFab',
                    onPressed: _showFilters,
                    child: Icon(Icons.filter_list),
                  ),
                if (narrow) const SizedBox(height: 12),
                const FloatingActionButton(
                  heroTag: 'addSpotFab',
                  onPressed: _addSpot,
                  child: Icon(Icons.add),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'newSpotFab',
                  onPressed: _newSpot,
                  icon: Icon(Icons.add),
                  label: Text('+ New Spot'),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'quickSpotFab',
                  onPressed: _quickSpot,
                  icon: Icon(Icons.flash_on),
                  label: Text('+ Quick Spot'),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton(
                  heroTag: 'generateSpotFab',
                  tooltip: 'Generate Spot',
                  onPressed: _generateSpot,
                  child: Icon(Icons.auto_fix_high),
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'generateSpotsFab',
                  icon: Icon(Icons.auto_fix_high),
                  label: Text('Generate Spots'),
                  onPressed: _generateSpots,
                ),
                const SizedBox(height: 12),
                const FloatingActionButton.extended(
                  heroTag: 'generateMissingFab',
                  icon: Icon(Icons.playlist_add),
                  label: Text('Generate Missing'),
                  onPressed: _generateMissingSpots,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'evalAllSpotsFab',
                  icon: _evaluatingAll
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_play),
                  label: const Text('Evaluate All'),
                  onPressed: _evaluatingAll ? null : _evaluateAllSpots,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'calcMissingFab',
                  icon: _calculatingMissing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate),
                  label: const Text('Calculate Missing EV/ICM'),
                  onPressed:
                      _calculatingMissing ? null : _calculateMissingEvIcm,
                ),
                if (canAddToLibrary) ...[
                  const SizedBox(height: 12),
                  const FloatingActionButton.extended(
                    heroTag: 'addToLibFab',
                    onPressed: _addToLibrary,
                    label: Text('Add to Library'),
                    icon: Icon(Icons.library_add),
                  ),
                ],
              ],
            )
          : showExample
              ? FloatingActionButton.extended(
                  heroTag: 'exampleFab',
                  onPressed: _generatingExample ? null : _generateExampleSpot,
                  icon: _generatingExample
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('Generate Example Spot'),
                )
              : null,
      bottomNavigationBar: widget.readOnly
          ? null
          : (_showScrollIndicator && !_previewMode)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      waitDuration: const Duration(milliseconds: 500),
                      showDuration: const Duration(seconds: 2),
                      message:
                          'Scrolled: ${(_scrollProgress * 100).toStringAsFixed(1)}%',
                      child: LinearProgressIndicator(
                        value: _scrollProgress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary),
                        minHeight: 2,
                      ),
                    ),
                  ],
                )
              : null,
      body: hasSpots
          ? _previewMode
              ? Stack(
                  children: [
                    if (_previewPath != null)
                      Positioned.fill(
                        child: Image.file(File(_previewPath!), fit: BoxFit.cover),
                      ),
                    if (_previewPath != null)
                      Positioned.fill(child: Container(color: Colors.black54)),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IconButton(
                            icon: Icon(Icons.table_chart),
                            onPressed: _exportPreviewCsv,
                          ),
                          const IconButton(
                            icon: Icon(Icons.download),
                            onPressed: _exportPreviewJson,
                          ),
                          const IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: _exportPreviewSummary,
                          ),
                          const IconButton(
                            icon: Icon(Icons.description),
                            onPressed: _exportPreviewMarkdown,
                            onLongPress: _previewMarkdown,
                          ),
                          Badge.count(
                            count: mistakeCount,
                            isLabelVisible: mistakeCount > 0,
                            child: const IconButton(
                              icon: Icon(Icons.archive),
                              onPressed: _exportPreviewZip,
                            ),
                          ),
                          const IconButton(
                            icon: Icon(Icons.share),
                            onPressed: _sharePreviewZip,
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_originPreset != null) _buildPresetBanner(),
                          Stack(
                            children: [
                              LinearProgressIndicator(
                                value: evTotal,
                                color: primaryColor,
                                backgroundColor: Colors.white24,
                                minHeight: 4,
                              ),
                              LinearProgressIndicator(
                                value: icmTotal,
                                color: primaryColor.withOpacity(0.4),
                                backgroundColor: Colors.transparent,
                                minHeight: 4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                    if (coverageWarningNeeded) ...[
                      GestureDetector(
                        onTap: _calculateMissingEvIcm,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Coverage incomplete: EV/ICM not computed for all spots',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _CoverageProgress(
                      label: 'EV Covered',
                      value: evCoverage,
                      color: Theme.of(context).colorScheme.secondary,
                      message: _evTooltip,
                    ),
                    const SizedBox(height: 8),
                    _CoverageProgress(
                      label: 'ICM Covered',
                      value: icmCoverage,
                      color: Colors.purple,
                      message: _icmTooltip,
                    ),
                    const SizedBox(height: 16),
            TemplateSummaryPanel(
              spots: totalSpots,
              evCount: evCovered,
              icmCount: icmCovered,
              tags: summaryTags,
              avgEv: avgEv,
            ),
                    const SizedBox(height: 16),
                    if (heroEvsAll.isNotEmpty)
                      EvDistributionChart(evs: heroEvsAll),
                  ],
                    ),
                  ],
                )
              : Stack(
              children: [
                if (_showImportIndicator)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: 1,
                      color: Colors.green,
                      backgroundColor: Colors.transparent,
                      minHeight: 4,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_originPreset != null) _buildPresetBanner(),
                  Stack(
                    children: [
                      LinearProgressIndicator(
                        value: evTotal,
                        color: primaryColor,
                        backgroundColor: Colors.white24,
                        minHeight: 4,
                      ),
                      LinearProgressIndicator(
                        value: icmTotal,
                        color: primaryColor.withOpacity(0.4),
                        backgroundColor: Colors.transparent,
                        minHeight: 4,
                      ),
                    ],
                  ),
                  Tooltip(
                    message: 'Mistake-free = number of spots without mistakes',
                    child: LinearProgressIndicator(
                      value: mistakePct,
                      color: Colors.redAccent,
                      backgroundColor: Colors.transparent,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
            if (coverageWarningNeeded) ...[
              GestureDetector(
                onTap: _calculateMissingEvIcm,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Coverage incomplete: EV/ICM not computed for all spots',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _CoverageProgress(
              label: 'EV Covered',
              value: evCoverage,
              color: Theme.of(context).colorScheme.secondary,
              message: _evTooltip,
            ),
            const SizedBox(height: 8),
            _CoverageProgress(
              label: 'ICM Covered',
              value: icmCoverage,
              color: Colors.purple,
              message: _icmTooltip,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtr,
              focusNode: _descFocus,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onEditingComplete: _saveDesc,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _evCtr,
              decoration:
                  const InputDecoration(labelText: 'Min EV to be correct (bb)'),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0.01;
                setState(() => widget.template.minEvForCorrect = val);
                _markAllDirty();
                _persist();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _anteCtr,
              decoration: const InputDecoration(labelText: 'Ante (BB)'),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                var val = int.tryParse(v) ?? 0;
                if (val < 0) val = 0;
                if (val > 5) val = 5;
                if (_anteCtr.text != '$val') {
                  _anteCtr.text = '$val';
                  _anteCtr.selection = TextSelection.fromPosition(
                      TextPosition(offset: _anteCtr.text.length));
                }
                setState(() => widget.template.anteBb = val);
                _markAllDirty();
                _persist();
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
                      _persist();
                    },
                  ),
                const InputChip(
                  label: Text('+ Add'),
                  onPressed: _addPackTag,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in widget.template.focusTags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() => widget.template.focusTags.remove(tag));
                      _persist();
                    },
                  ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _focusCtr,
                    decoration: const InputDecoration(hintText: 'Focus tag'),
                    onSubmitted: (v) => _addFocusTag(v.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final t in widget.template.focusHandTypes)
                  InputChip(
                    label: Text(t.toString()),
                    onDeleted: () {
                      setState(() => widget.template.focusHandTypes.remove(t));
                      _persist();
                      if (mounted) setState(() {});
                    },
                  ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _handTypeCtr,
                    decoration: const InputDecoration(hintText: 'Hand type'),
                    onSubmitted: (v) => _addHandType(v.trim()),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('e.g. JXs, 76s+, suited connectors',
                  style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 8),
            if (handCounts.isNotEmpty)
              ExpansionTile(
                title: Row(
                  children: [
                    const Text('Focus coverage'),
                    const SizedBox(width: 8),
                    Text(
                      '(avg ${focusAvg == null ? 'N/A' : '${focusAvg.round()}%'})',
                      style: TextStyle(
                        color: focusAvg == null
                            ? Colors.white
                            : focusAvg < 70
                                ? Colors.red
                                : focusAvg < 90
                                    ? Colors.yellow
                                    : Colors.green,
                      ),
                    ),
                  ],
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                collapsedTextColor: Colors.white,
                textColor: Colors.white,
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final g in widget.template.focusHandTypes)
                        (() {
                          final count = handCounts[g.label] ?? 0;
                          final total = handTotals[g.label] ?? 0;
                          final pct = total == 0 ? 0 : (count * 100 / total).round();
                          final bg = pct < 70 ? Colors.red : Colors.grey[800];
                          return Chip(
                            backgroundColor: bg,
                            label: Text(
                              '${g.label}: $count/$total ($pct%)',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        })(),
                    ],
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
                _persist();
              },
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, set) => EvSummaryCard(
                values: _summaryIcm ? icmVals : chipVals,
                isIcm: _summaryIcm,
                onToggle: () => set(() => _summaryIcm = !_summaryIcm),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: RangeMatrixPicker(
                  selected: range,
                  highlight: widget.template.heroRange?.toSet(),
                  onChanged: (_) {},
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const RangeLegend(),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Edit History', style: TextStyle(color: Colors.white)),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              collapsedTextColor: Colors.white,
              textColor: Colors.white,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_history.history.isEmpty)
                  const ListTile(
                    dense: true,
                    title: Text('No changes yet', style: TextStyle(color: Colors.white70)),
                  )
                else
                  for (final entry in historyGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(entry.key, style: const TextStyle(color: Colors.white70)),
                    ),
                    for (final e in entry.value)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          e.action == 'Added'
                              ? Icons.add_circle
                              : e.action == 'Deleted'
                                  ? Icons.remove_circle
                                  : e.action == 'Tagged'
                                      ? Icons.local_offer
                                      : e.action == 'Untagged'
                                          ? Icons.local_offer_outlined
                                          : Icons.edit,
                          color: e.action == 'Added'
                              ? Colors.green
                              : e.action == 'Deleted'
                                  ? Colors.red
                                  : e.action == 'Tagged'
                                      ? Colors.orange
                                      : e.action == 'Untagged'
                                          ? Colors.grey
                                          : Colors.blue,
                        ),
                        title: Text('${e.action}: ${e.title}',
                            style: const TextStyle(color: Colors.white)),
                        trailing: Text(DateFormat.Hm().format(e.time),
                            style: const TextStyle(color: Colors.white70)),
                      ),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            if (!narrow)
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
                        ButtonSegment(value: 'ok', label: Text('OK')),
                        ButtonSegment(value: 'error', label: Text('Errors')),
                        ButtonSegment(value: 'empty', label: Text('Empty')),
                      ],
                      selected: {_evFilter},
                      onSelectionChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v.first;
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _evFilter,
                      decoration: const InputDecoration(labelText: 'EV'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'ok', child: Text('OK')),
                        DropdownMenuItem(value: 'error', child: Text('Errors')),
                        DropdownMenuItem(value: 'empty', child: Text('Empty')),
                      ],
                      onChanged: (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        final val = v ?? 'all';
                        setState(() => _evFilter = val);
                        prefs.setString(_prefsEvFilterKey, val);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EV range (BB)',
                          style: TextStyle(color: Colors.white70)),
                      RangeSlider(
                        values: _evRange,
                        min: -5,
                        max: 5,
                        divisions: 100,
                        labels: RangeLabels(
                          _evRange.start.toStringAsFixed(1),
                          _evRange.end.toStringAsFixed(1),
                        ),
                        onChanged: (v) async {
                          setState(() => _evRange = v);
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setString(
                              _prefsEvRangeKey, '${v.start},${v.end}');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_evRange.start.toStringAsFixed(1)} … ${_evRange.end.toStringAsFixed(1)} BB',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() => _evRange = const RangeValues(-5, 5));
                    prefs.setString(_prefsEvRangeKey, '-5.0,5.0');
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _generatingAll ? null : _generateAllEv,
                    child: _generatingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate All'),
                  ),
                  ElevatedButton(
                    onPressed: _generatingIcm ? null : _generateAllIcm,
                    child: _generatingIcm
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate ICM'),
                  ),
                  const ElevatedButton(
                    onPressed: _recalculateAll,
                    child: Text('Recalculate All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TemplateSummaryPanel(
              spots: totalSpots,
              evCount: evCovered,
              icmCount: icmCovered,
              tags: summaryTags,
              avgEv: avgEv,
            ),
            const SizedBox(height: 8),
            _EvCoverageBar(ev: evCoverage, icm: icmCoverage, both: bothCoverage),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _tagFilter ?? '',
                decoration: const InputDecoration(labelText: 'Filter by tag'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All')),
                  for (final t in widget.template.spots
                      .expand((s) => s.tags)
                      .toSet()
                      .toList()
                    ..sort())
                    DropdownMenuItem(value: t.toLowerCase(), child: Text(t)),
                ],
                onChanged: (v) async {
                  setState(
                      () => _tagFilter = (v == null || v.isEmpty) ? null : v);
                  _storeTagFilter();
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hero push only'),
              value: _heroPushOnly,
              onChanged: (v) => setState(() => _heroPushOnly = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Mistakes'),
                    selected: _filterMistakes,
                    onSelected: (v) => setState(() => _filterMistakes = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Outdated'),
                    selected: _filterOutdated,
                    onSelected: (v) => setState(() => _filterOutdated = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('EV Covered'),
                    selected: _filterEvCovered,
                    onSelected: (v) => setState(() => _filterEvCovered = v),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              title: const Text('Only Changed'),
              value: _changedOnly,
              onChanged: (v) => setState(() => _changedOnly = v ?? false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<SpotSort>(
                value: _spotSort,
                decoration: const InputDecoration(labelText: 'Sort'),
                items: const [
                  DropdownMenuItem(
                      value: SpotSort.original, child: Text('Default')),
                  DropdownMenuItem(value: SpotSort.evDesc, child: Text('EV ↓')),
                  DropdownMenuItem(value: SpotSort.evAsc, child: Text('EV ↑')),
                  DropdownMenuItem(value: SpotSort.icmDesc, child: Text('ICM ↓')),
                  DropdownMenuItem(value: SpotSort.icmAsc, child: Text('ICM ↑')),
                  DropdownMenuItem(
                      value: SpotSort.priorityDesc, child: Text('Priority')),
                ],
                onChanged: (v) =>
                    setState(() => _spotSort = v ?? SpotSort.original),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final rows = _buildRows(sorted);
                  return NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      _scrollDebounce?.cancel();
                      _scrollDebounce =
                          Timer(const Duration(milliseconds: 300), _storeScroll);
                      return false;
                    },
                    child: DragAutoScroll(
                      controller: _scrollCtrl,
                      child: ReorderableListView.builder(
                        key: const PageStorageKey('spotsList'),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: rows.length,
                        proxyDecorator: _proxyLift,
                        onReorder: (oldIndex, newIndex) {
                          final moved = rows.removeAt(oldIndex);
                          rows.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, moved);
                          _recordSnapshot();
                          widget.template.spots
                            ..clear()
                            ..addAll(rows.where((r) => r.kind == _RowKind.spot).map((r) => r.spot!));
                          _persist();
                          WidgetsBinding.instance.addPostFrameCallback((_) =>
                              _focusSpot(moved.spot?.id ?? ''));
                        },
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          if (r.kind == _RowKind.header) {
                            return Padding(
                              key: ValueKey('hdr_${r.tag}'),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Text(
                                r.tag.isEmpty ? 'Untagged' : r.tag,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            );
                          }
                          final spot = r.spot!;
                          final selected = _selectedSpotIds.contains(spot.id);
                          final showDup =
                              (spot.isNew && _importDuplicateGroups([spot])) ||
                                  _isDup(spot);
                          final content = ReorderableDragStartListener(
                            key: ValueKey(spot.id),
                            index: i,
                            child: InkWell(
                            onTap: () async {
                              await showSpotViewerDialog(
                                context,
                                spot,
                                templateTags: widget.template.tags,
                              );
                              if (_autoSortEv) setState(() => _sortSpots());
                              _focusSpot(spot.id);
                            },
                            onLongPress: () {
                              setState(() => _selectedSpotIds.add(spot.id));
                              _maybeShowMultiTip();
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: RepaintBoundary(
                                key: _itemKeys.putIfAbsent(spot.id, () => GlobalKey()),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  color: spot.id == _highlightId
                                          ? Colors.yellow.withOpacity(0.3)
                                          : spot.isNew
                                              ? Colors.yellow.withOpacity(0.1)
                                              : spot.dirty
                                                  ? Colors.blue.withOpacity(0.05)
                                                  : null,
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                                      if (_isMultiSelect)
                                        Checkbox(
                                          value: selected,
                                          onChanged: (_) {
                                            setState(() {
                                              if (selected) {
                                                _selectedSpotIds.remove(spot.id);
                                              } else {
                                                _selectedSpotIds.add(spot.id);
                                              }
                                            });
                                            _maybeShowMultiTip();
                                          },
                                        ),
                                      Expanded(
                                        child: TrainingPackSpotPreviewCard(
                                          spot: spot,
                                          editableTitle: true,
                                          onTitleChanged: (_) {
                                            setState(() {});
                                            _persist();
                                          },
                                          isMistake: spot.evalResult?.correct == false,
                                          titleColor: spot.evalResult == null
                                              ? Colors.yellow
                                              : (spot.evalResult!.correct ? null : Colors.red),
                                          onHandEdited: () {
                                            unawaited(() async {
                                              try {
                                                spot.dirty = false;
                                                await context.read<EvaluationExecutorService>().evaluateSingle(
                                                      context,
                                                      spot,
                                                      template: widget.template,
                                                      anteBb: widget.template.anteBb,
                                                    );
                                              } catch (_) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Evaluation failed')));
                                                }
                                              }
                                              if (!mounted) return;
                                              setState(() {
                                                if (_autoSortEv) _sortSpots();
                                              });
                                              await _persist();
                                            }());
                                          },
                                          onTagTap: (tag) async {
                                            setState(() => _tagFilter = tag);
                                            _storeTagFilter();
                                          },
                                          template: widget.template,
                                          persist: _persist,
                                          focusSpot: _focusSpot,
                                          onNewTap: _selectAllNew,
                                          onDupTap: _selectAllDuplicates,
                                          onPersist: _persist,
                                          showDuplicate: showDup,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildSpotMenu(spot),
                                          TextButton(
                                            onPressed: () => _openEditor(spot),
                                            child: const Text('📝 Edit'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: () {
                                              final evalSpot = _toSpot(spot);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => SpotSolveScreen(
                                                    spot: evalSpot,
                                                    packSpot: spot,
                                                    template: widget.template,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Remove this spot from the pack?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('Remove'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok ?? false) {
                                                final t = spot.title;
                                                setState(() => widget.template.spots.removeAt(
                                                    widget.template.spots.indexOf(spot)));
                                                await _persist();
                                                setState(() => _history.log('Deleted', t, spot.id));
                                              }
                                            },
                                          ),
                                          if (_isMultiSelect)
                                            const IconButton(
                                              icon: Icon(Icons.delete_forever, color: Colors.red),
                                              onPressed: _bulkDeleteQuick,
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
                                final t = spot.title;
                                setState(() => widget.template.spots.remove(spot));
                                _persist();
                                setState(() => _history.log('Deleted', t, spot.id));
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
                                        _persist();
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
                      ),
                    ),
                  );
                },
              ),
            ),
            ],
          ),
        ),
        )
            : Stack(
                children: [
                  if (_showImportIndicator)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: 1,
                        color: Colors.green,
                        backgroundColor: Colors.transparent,
                        minHeight: 4,
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  const Icon(Icons.lightbulb_outline, size: 96, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    showExample
                        ? 'This pack is empty. Tap + to add a spot, 📋 to paste from JSON or use the wand to generate an example'
                        : 'This pack is empty. Tap + to add your first spot or 📋 to paste from JSON',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showExample) ...[
                        ElevatedButton.icon(
                          onPressed:
                              _generatingExample ? null : _generateExampleSpot,
                          icon: _generatingExample
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_fix_high),
                          label: const Text('Example'),
                        ),
                        const SizedBox(width: 12),
                      ],
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
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pasteHandHistory,
                        icon: const Text('📥'),
                        label: const Text('Paste Hand'),
                      ),
                    ],
                  ),
                ],
              ),
            );
  }
}

class _TemplatePreviewCard extends StatefulWidget {
  final TrainingPackTemplate template;
  const _TemplatePreviewCard({required this.template});

  @override
  State<_TemplatePreviewCard> createState() => _TemplatePreviewCardState();
}

class _TemplatePreviewCardState extends State<_TemplatePreviewCard> {
  String? previewPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final png = widget.template.png;
    if (png != null) {
      final path = await PreviewCacheService.instance.getPreviewPath(png);
      if (!mounted) return;
      setState(() => previewPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.template.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (widget.template.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(widget.template.description),
              ),
            if (widget.template.focusTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('🎯 Focus: ${widget.template.focusTags.join(', ')}'),
              ),
            if (widget.template.focusHandTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('🎯 Hand Goal: ${widget.template.focusHandTypes.join(', ')}'),
              ),
            if (widget.template.heroRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.template.handTypeSummary(),
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Spots: ${widget.template.spots.length}'),
              ),
          ],
        ),
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (previewPath != null)
            Positioned.fill(
              child: Image.file(File(previewPath!), fit: BoxFit.cover),
            ),
          if (previewPath != null)
            Positioned.fill(child: Container(color: Colors.black45)),
          content,
        ],
      ),
    );
  }
}

class _ManageTagTile extends StatefulWidget {
  final String tag;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  const _ManageTagTile({required this.tag, required this.onRename, required this.onDelete});

  @override
  State<_ManageTagTile> createState() => _ManageTagTileState();
}

class _ManageTagTileState extends State<_ManageTagTile> {
  late TextEditingController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = TextEditingController(text: widget.tag);
  }

  @override
  void didUpdateWidget(covariant _ManageTagTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) _ctr.text = widget.tag;
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Text('✏️'),
      title: TextField(
        controller: _ctr,
        decoration: const InputDecoration(border: InputBorder.none),
        onSubmitted: (v) {
          final t = v.trim();
          if (t.isEmpty || t == widget.tag) {
            _ctr.text = widget.tag;
          } else {
            widget.onRename(t);
          }
        },
      ),
      trailing: IconButton(
        icon: const Text('🗑️'),
        onPressed: widget.onDelete,
      ),
    );
  }
}

class _EvCoverageBar extends StatelessWidget {
  final double ev;
  final double icm;
  final double both;
  const _EvCoverageBar({required this.ev, required this.icm, required this.both});

  Widget _bar(BuildContext context, double value, String label, Color color) {
    final percent = (value * 100).round();
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text('$label $percent%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Row(
      children: [
        _bar(context, ev, 'EV', accent),
        const SizedBox(width: 8),
        _bar(context, icm, 'ICM', Colors.purple),
        const SizedBox(width: 8),
        _bar(context, both, 'Both', Colors.green),
      ],
    );
  }
}

const _evTooltip = 'Calculated expected value (EV) for this spot';
const _icmTooltip = 'Calculated equity in tournament ICM model';

class _CoverageProgress extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String message;
  const _CoverageProgress({
    required this.label,
    required this.value,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).toStringAsFixed(0)}%';
    final offset = MediaQuery.of(context).padding.top;
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 300),
      preferBelow: false,
      preferAbove: false,
      verticalOffset: offset,
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                Text(percent, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

