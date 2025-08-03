part of 'training_pack_template_editor_screen.dart';

  List<TrainingPackSpot> _filterSpots() {
    var base = widget.template.spots;
    if (_newOnly) {
      base = [for (final s in base) if (s.isNew) s];
    }
    if (_duplicatesOnly) {
      base = [for (final s in base) if (_isDup(s)) s];
    }
    if (_priorityFilter != null) {
      base = [for (final s in base) if (s.priority == _priorityFilter) s];
    }
    final changed =
        _changedOnly ? _history.history.map((e) => e.id).toSet() : null;
    final list = base.where((s) {
      if (_pinnedOnly && !s.pinned) return false;
      final res = s.evalResult;
      if (_evFilter == 'ok' && !(res != null && res.correct)) return false;
      if (_evFilter == 'error' && !(res != null && !res.correct)) return false;
      if (_evFilter == 'empty' && res != null) return false;
      if (_filterOutdated && !s.dirty) return false;
      if (_filterEvCovered && !(s.heroEv != null && !s.dirty)) return false;
      if (_quickFilter == 'BTN' && s.hand.position != HeroPosition.btn) {
        return false;
      }
      if (_quickFilter == 'SB' && s.hand.position != HeroPosition.sb) {
        return false;
      }
      if (_quickFilter == 'Hero push only') {
        final acts = s.hand.actions[0] ?? [];
        final push = acts.any(
            (a) => a.playerIndex == s.hand.heroIndex && a.action == 'push');
        if (!push) return false;
      }
      if (_quickFilter == 'Mistake spots' && !(res != null && !res.correct)) {
        return false;
      }
      if (_quickFilter == 'High priority' && s.priority < 4) {
        return false;
      }
      if (_heroPushOnly) {
        final acts = s.hand.actions[0] ?? [];
        final hero = acts.where((a) => a.playerIndex == s.hand.heroIndex);
        final set = {for (final a in hero) a.action};
        if (!(set.length == 1 && set.contains('push'))) return false;
      }
      if (_selectedTags.isNotEmpty && !s.tags.any(_selectedTags.contains)) {
        return false;
      }
      if (_tagFilter != null &&
          !s.tags.any((t) => t.toLowerCase() == _tagFilter)) {
        return false;
      }
      final ev = s.heroEv;
      if (ev != null && (ev < _evRange.start || ev > _evRange.end)) {
        return false;
      }
      if (changed != null && !changed.contains(s.id)) return false;
      if (_query.isEmpty) return true;
      final q = _query;
      return s.hand.heroCards.toLowerCase().contains(q) ||
          s.hand.position.label.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
    return list;
  }

  List<TrainingPackSpot> _visibleSpots() {
    var list = _filterSpots();
    if (_positionFilter != null) {
      list = [for (final s in list) if (s.hand.position.label == _positionFilter) s];
    }
    if (_filterMistakes) {
      list = [
        for (final s in list)
          if (s.tags.contains('Mistake') || s.evalResult?.correct == false) s
      ];
    }
    if (_showMissingOnly) {
      list = [
        for (final s in list)
          if (s.heroEv == null || s.heroIcmEv == null || s.dirty) s
      ];
    }
    if (_sortMode == SortMode.chronological) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    if (_sortEvAsc) {
      list.sort((a, b) => (a.heroEv ?? 0).compareTo(b.heroEv ?? 0));
    }
    if (_mistakeFirst) {
      final m = [for (final s in list) if (s.tags.contains('Mistake')) s];
      final o = [for (final s in list) if (!s.tags.contains('Mistake')) s];
      list = [...m, ...o];
    }
    return list;
  }

  int _visibleSpotsCount() {
    var list = _filterSpots();
    if (_positionFilter != null) {
      list = [for (final s in list) if (s.hand.position.label == _positionFilter) s];
    }
    if (_filterMistakes) {
      list = [
        for (final s in list)
          if (s.tags.contains('Mistake') || s.evalResult?.correct == false) s
      ];
    }
    if (_showMissingOnly) {
      list = [
        for (final s in list)
          if (s.heroEv == null || s.heroIcmEv == null || s.dirty) s
      ];
    }
    return list.length;
  }

  List<String> _positionsInView() {
    final set = {for (final s in _filterSpots()) s.hand.position.label};
    final list = set.toList()..sort();
    return list;
  }

  List<_Row> _buildRows(List<TrainingPackSpot> list) {
    final rows = <_Row>[];
    final map = <String, List<TrainingPackSpot>>{};
    for (final s in list) {
      final tag = s.tags.isEmpty ? '' : s.tags.first;
      map.putIfAbsent(tag, () => []).add(s);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in entries) {
      rows.add(_Row.header(e.key));
      for (final s in e.value) {
        rows.add(_Row.spot(s));
      }
    }
    return rows;
  }

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

  double _itemOffset(int index) {
    final id = widget.template.spots[index].id;
    final ctx = _itemKeys[id]?.currentContext;
    if (ctx == null) return 0;
    final box = ctx.findRenderObject() as RenderBox;
    final ancestor = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: ancestor).dy;
    return _scrollCtrl.offset + pos;
  }

  void _recordSnapshot() => _history.record(widget.template.spots);

  void _markAllDirty() {
    for (final s in widget.template.spots) {
      s.dirty = true;
    }
  }

  void _log(String action, TrainingPackSpot spot) {
    _history.log(action, spot.title, spot.id);
    final key = _itemKeys[spot.id];
    if (key?.currentContext != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focusSpot(spot.id));
    }
  }

  Future<void> _openEditor(TrainingPackSpot spot) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackSpotEditorScreen(
          spot: spot,
          templateTags: widget.template.tags,
          trainingType: widget.template.trainingType,
        ),
      ),
    );
    try {
      spot.dirty = false;
      await context
          .read<EvaluationExecutorService>()
          .evaluateSingle(
            context,
            spot,
            template: widget.template,
            anteBb: widget.template.anteBb,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Evaluation failed')));
      }
    }
    }
    dynamic if (!mounted) return;
    setState(() {
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    void if (mounted) setState(() => _log('Edited', spot));
  }

  TrainingSpot _toSpot(TrainingPackSpot spot) {
    final hand = spot.hand;
    final heroCards = hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
        .toList();
    final playerCards = [
      for (int i = 0; i < hand.playerCount; i++) <CardModel>[]
    ];
    if (heroCards.length >= 2 && hand.heroIndex < playerCards.length) {
      playerCards[hand.heroIndex] = heroCards;
    }
    final boardCards = [
      for (final c in hand.board) CardModel(rank: c[0], suit: c.substring(1))
    ];
    final actions = <ActionEntry>[];
    for (final list in hand.actions.values) {
      for (final a in list) {
        actions.add(ActionEntry(a.street, a.playerIndex, a.action,
            amount: a.amount,
            generated: a.generated,
            manualEvaluation: a.manualEvaluation,
            customLabel: a.customLabel));
      }
    }
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++)
        hand.stacks['$i']?.round() ?? 0
    ];
    final positions = List.generate(hand.playerCount, (_) => '');
    if (hand.heroIndex < positions.length) {
      positions[hand.heroIndex] = hand.position.label;
    }
    return TrainingSpot(
      playerCards: playerCards,
      boardCards: boardCards,
      actions: actions,
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.playerCount,
      playerTypes: List.generate(hand.playerCount, (_) => PlayerType.unknown),
      positions: positions,
      stacks: stacks,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _persist() async {
    if (widget.readOnly) return;
    widget.template.isDraft = true;
    TemplateCoverageUtils.recountAll(widget.template).applyTo(widget.template.meta);
    context.read<TemplateStorageService>().updateTemplate(widget.template);
    setState(() {});
    await TrainingPackStorage.save(widget.templates);
  }

  void _saveOnly() {
    TrainingPackStorage.save(widget.templates);
  }

  Future<void> _saveSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tpl_snapshots_${widget.template.id}',
      jsonEncode([for (final s in _snapshots) s.toJson()]),
    );
  }

  Future<void> _saveSnapshotAction() async {
    final c = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Snapshot'),
        content: TextField(controller: c, autofocus: true),
        actions: widget.readOnly
            ? [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ]
            : [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (comment == null) return;
    final snap = _history.saveSnapshot(widget.template.spots, comment);
    setState(() => _snapshots.add(snap));
    await _saveSnapshots();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Snapshot saved')));
    }
  }

  Future<void> _undo() async {
    final snap = _history.undo(widget.template.spots);
    if (snap == null) return;
    setState(() {
      widget.template.spots
        ..clear()
        ..addAll(snap);
    });
    await _persist();
  }

  Future<void> _redo() async {
    final snap = _history.redo(widget.template.spots);
    if (snap == null) return;
    setState(() {
      widget.template.spots
        ..clear()
        ..addAll(snap);
    });
    await _persist();
  }

  void _jumpToLastChange() {
    final entry = _history.history.isEmpty ? null : _history.history.first;
    if (entry == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No recent changes')));
      return;
    }
    final spot = widget.template.spots
        .firstWhereOrNull((s) => s.id == entry.id || s.title == entry.title);
    if (spot == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No recent changes')));
      return;
    }
    _focusSpot(spot.id);
  }

  Future<void> _showSnapshots() async {
    final snap =
        await showSnapshotListDialog(context, _history.snapshots);
    if (snap == null) return;
    setState(() {
      widget.template.spots
        ..clear()
        ..addAll([for (final s in snap.spots) TrainingPackSpot.fromJson(s.toJson())]);
    });
    await _persist();
    _history.record(widget.template.spots);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Snapshot restored')));
    }
  }

  Widget _buildPresetBanner() {
    final p = _originPreset;
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: AppColors.cardBackground,
        child: ListTile(
          title: Text(p.name, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(p.description, style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  Future<void> _addSpot() async {
    _recordSnapshot();
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      title: normalizeSpotTitle('New spot'),
    );
    setState(() => widget.template.spots.add(spot));
    await _persist();
    if (mounted) setState(() {});
    setState(() => _log('Added', spot));
    await _openEditor(spot);
  }

  Future<void> _newSpot() async {
    _recordSnapshot();
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
    );
    setState(() => widget.template.spots.insert(0, spot));
    await _persist();
    setState(() => _log('Added', spot));
    await _openEditor(spot);
    if (mounted) setState(() {});
    if (mounted) setState(() {});
  }

  Future<void> _quickSpot() async {
    final cardCtr = TextEditingController();
    final stackCtr = TextEditingController(text: '10');
    HeroPosition pos = widget.template.heroPos;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardCtr,
                decoration: const InputDecoration(labelText: 'Hero cards'),
              ),
              const SizedBox(height: 8),
              DropdownButton<HeroPosition>(
                value: pos,
                items: [
                  for (final p in kPositionOrder)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
                onChanged: (v) => set(() => pos = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stackCtr,
                decoration: const InputDecoration(labelText: 'Stacks (BB)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final cards = cardCtr.text.trim();
    final stack = int.tryParse(stackCtr.text) ?? 10;
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData.fromSimpleInput(cards, pos, stack),
    );
    await context.read<EvaluationExecutorService>().evaluateSingle(
      context,
      spot,
      template: widget.template,
      anteBb: widget.template.anteBb,
    );
    setState(() => widget.template.spots.insert(0, spot));
    await _persist();
  }

  Future<void> _generateSpot() async {
    _recordSnapshot();
    final spot = TrainingPackSpot(
      id: const Uuid().v4(),
      title: 'New Spot',
    );
    setState(() => widget.template.spots.add(spot));
    await _persist();
    setState(() => _log('Added', spot));
    await _openEditor(spot);
  }

  Future<void> _generateExampleSpot() async {
    final variants = widget.template.playableVariants();
    if (variants.length != 1) return;
    if (widget.template.spots.any((s) => s.dirty)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text(
              'Discard unsaved changes and generate new spot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _generatingExample = true);
    try {
      final spot =
          await PackGeneratorService.generateExampleSpot(widget.template, variants.first);
      if (!mounted) return;
      setState(() => widget.template.spots.add(spot));
      await _persist();
      setState(() => _log('Added', spot));
      try {
        await context
            .read<EvaluationExecutorService>()
            .evaluateSingle(
              context,
              spot,
              template: widget.template,
              anteBb: widget.template.anteBb,
            );
        await _persist();
        if (mounted) setState(() {});
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Evaluation failed')));
        }
      }
      await _openEditor(spot);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to generate: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingExample = false);
    }
  }

  Future<void> _generateSpots() async {
    _recordSnapshot();
    const service = TrainingPackTemplateUiService();
    final generated =
        await service.generateSpotsWithProgress(context, widget.template);
    if (!mounted) return;
    setState(() {
      widget.template.spots.addAll(generated);
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    if (generated.isNotEmpty) {
      setState(() => _history.log('Added', '${generated.length} spots', ''));
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Generated ${generated.length} spots')));
  }

  Future<void> _generateMissingSpots() async {
    const service = TrainingPackTemplateUiService();
    final missing =
        await service.generateMissingSpotsWithProgress(context, widget.template);
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All spots already present 🎉')));
      return;
    }
    setState(() {
      widget.template.spots.addAll(missing);
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    setState(() => _history.log('Added', '${missing.length} spots', ''));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added ${missing.length} spots')));
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
    _recordSnapshot();
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
      await _persist();
      setState(() => _log('Added', spot));
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

  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _spotFromHand(SavedHand hand) {
    final heroCards = hand.playerCards[hand.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[for (final a in hand.actions) if (a.street == 0) a];
    final stacks = <String, double>{
      for (int i = 0; i < hand.numberOfPlayers; i++) '$i': (hand.stackSizes[i] ?? 0).toDouble()
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      isNew: true,
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(hand.heroPosition),
        heroIndex: hand.heroIndex,
        playerCount: hand.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
        actions: {0: actions},
      ),
    );
  }

  Future<void> _pasteHandHistory() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Hand History'),
        content: TextField(controller: c, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    _recordSnapshot();
    if (text == null || text.trim().isEmpty) return;
    final importer = await RoomHandHistoryImporter.create();
    final hands = importer.parse(text);
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid hand')));
      }
      return;
    }
    final spot = _spotFromHand(hands.first);
    setState(() {
      widget.template.spots.add(spot);
      if (_autoSortEv) _sortSpots();
    });
    await _persist();
    setState(() => _log('Added', spot));
  }

  Future<void> _importFromClipboardSpots() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    final importer = await RoomHandHistoryImporter.create();
    final hands = importer.parse(text);
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Не удалось распознать раздачи')));
      }
      return;
    }
    _recordSnapshot();
    _pasteUndo = [for (final s in widget.template.spots) TrainingPackSpot.fromJson(s.toJson())];
    final spots = [for (final h in hands) _spotFromHand(h)];
    setState(() {
      widget.template.spots.addAll(spots);
      if (_autoSortEv) _sortSpots();
      for (final s in spots) {
        s.isNew = true;
      }
      _showImportIndicator = true;
      _showPasteBubble = false;
    });
    Future.delayed(const Duration(seconds: 30), () {
      if (!mounted) return;
      var changed = false;
      for (final s in spots) {
        if (s.isNew) {
          s.isNew = false;
          changed = true;
        }
      }
      if (_newOnly && widget.template.spots.every((s) => !s.isNew)) {
        setState(() => _newOnly = false);
        _storeNewOnly();
      } else if (changed) {
        setState(() {});
      }
    });
    _importTimer?.cancel();
    _importTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showImportIndicator = false);
      if (mounted) setState(() => _showImportIndicator = false);
    });
    await _persist();
    final hasDup = _importDuplicateGroups(spots);
    if (hasDup) setState(() => _showDupHint = true);
    for (final s in spots) {
      _log('Added', s);
    }
    final addedIds = [for (final s in spots) s.id];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported ${spots.length} spots'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (_pasteUndo != null) {
              setState(() {
                widget.template.spots
                  ..clear()
                  ..addAll(_pasteUndo!);
                if (_autoSortEv) _sortSpots();
              });
              _persist();
            }
          },
        ),
      ),
    );
    if (addedIds.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.label, color: Colors.white),
                title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _bulkAddTag(addedIds);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move, color: Colors.white),
                title: const Text('Move to Pack', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _bulkTransfer(true, addedIds);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title: const Text('Skip', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      )
    }
    if (spots.length <= 3) {
      await showSpotViewerDialog(
        context,
        spots.first,
        templateTags: widget.template.tags,
        trainingType: widget.template.trainingType,
      );
    }
  }

  Future<void> _clearClipboard() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    if (!mounted) return;
    setState(() => _showPasteBubble = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Clipboard cleared')));
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final txt = data?.text?.trim() ?? '';
    final show = containsPokerHistoryMarkers(txt);
    if (show != _showPasteBubble) setState(() => _showPasteBubble = show);
  }

  void _undoImport() {
    final removed = [for (final s in widget.template.spots) if (s.isNew) s];
    if (removed.isEmpty) return;
    _recordSnapshot();
    final ids = {for (final s in removed) s.id};
    setState(() {
      widget.template.spots.removeWhere((s) => ids.contains(s.id));
      _selectedSpotIds.removeWhere(ids.contains);
      _showDupHint = false;
    });
    _persist();
    if (mounted) setState(() {});
    setState(() => _history.log('Deleted', '${removed.length} spots', ''));
  }

  Future<void> _addPackTag() async {
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
    setState(() {
      if (!widget.template.tags.contains(tag)) {
        widget.template.tags.add(tag);
      }
    });
    _persist();
  }

  void _addFocusTag(String tag) {
    if (tag.isEmpty) return;
    setState(() => widget.template.focusTags.add(tag));
    _focusCtr.clear();
    _persist();
  }

  void _addHandType(String val) {
    final parts = val.split(':');
    final label = parts.first.trim();
    final label = parts.first.trim();
    final weight = parts.length > 1 ? int.tryParse(parts[1]) ?? 100 : 100;
    final err = handTypeLabelError(label);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => widget.template.focusHandTypes.add(FocusGoal(label, weight)));
    _handTypeCtr.clear();
    _persist();
    if (mounted) setState(() {});
    final tag = _tagForHandType(label);
    if (tag != null && !widget.template.tags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text("Add tag '$tag' for this hand goal?")),
              TextButton(
                onPressed: () {
                  setState(() => widget.template.tags.add(tag));
                  _persist();
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                },
                child: const Text('Add'),
              ),
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).removeCurrentSnackBar(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    }
  }

  String? _tagForHandType(String label) {
    final l = label.trim().toUpperCase();
    if (l == 'SUITED CONNECTORS') return 'SC';
    if (l == 'OFFSUIT CONNECTORS') return 'OC';
    final m = RegExp(r'^([2-9TJQKA])X([SO])?$').firstMatch(l);
    if (m != null) {
      final r = m.group(1)!;
      final s = m.group(2);
      if (s == 'S') return '${r}xs';
      if (s == 'O') return '${r}xo';
      return '${r}x';
    }
    return null;
  }

  void _saveDesc() {
    setState(() => widget.template.description = _descCtr.text.trim());
    _persist();
  }

  Future<void> _renameTemplate() async {
    final ctrl = TextEditingController(text: _templateName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
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
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          _templateName = name;
          widget.template.name = name;
        });
        final service = context.read<TrainingPackTemplateStorageService>();
        await service.saveAll();
        await _persist();
      }
    }
    ctrl.dispose();
