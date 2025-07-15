part of 'training_pack_template_editor_screen.dart';


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
    String _rangeStr = widget.template.heroRange?.join(' ') ?? '';
    String rangeMode = 'simple';
    final rangeCtr = TextEditingController(text: _rangeStr);
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
                              _rangeStr = v;
                              rangeErr = v.trim().isNotEmpty &&
                                  PackGeneratorService.parseRangeString(v).isEmpty;
                            }),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final init = PackGeneratorService
                                  .parseRangeString(_rangeStr)
                                  .toSet();
                              final res = await Navigator.push<Set<String>>(
                                context,
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => _MatrixPickerPage(initial: init),
                                ),
                              );
                              if (res != null) set(() {
                                _rangeStr = PackGeneratorService.serializeRange(res);
                                rangeCtr.text = _rangeStr;
                                rangeErr = _rangeStr.trim().isNotEmpty &&
                                    PackGeneratorService.parseRangeString(_rangeStr).isEmpty;
                              });
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hero Range',
                                errorText: rangeErr ? '' : null,
                              ),
                              child: Text(
                                _rangeStr.isEmpty ? 'All hands' : _rangeStr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final range = await const RangeImportExportService()
                          .readRange(widget.template.id);
                      if (range != null) set(() {
                        _rangeStr = range.join(' ');
                        rangeCtr.text = _rangeStr;
                        rangeErr = _rangeStr.trim().isNotEmpty &&
                            PackGeneratorService.parseRangeString(_rangeStr).isEmpty;
                      });
                    },
                    child: const Text('Import Range'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final list =
                          PackGeneratorService.parseRangeString(_rangeStr).toList();
                      await const RangeImportExportService()
                          .writeRange(widget.template.id, list);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Range saved')));
                      }
                    },
                    child: const Text('Export Range'),
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
      final parsedSet = PackGeneratorService.parseRangeString(_rangeStr);
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
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Template settings updated')));
      }
    }
    heroCtr.dispose();
    for (final c in stackCtrs) c.dispose();
    countCtr.dispose();
    anteCtr.dispose();
    rangeCtr.dispose();
    thresholdCtr.dispose();
  }
