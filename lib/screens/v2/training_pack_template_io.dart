part of 'training_pack_template_list_screen.dart';

mixin TrainingPackTemplateIo on State<TrainingPackTemplateListScreen> {
  Future<void> _export() async {
    final json = jsonEncode([
      for (final t in _templates)
        if (!t.isDraft) t.toJson()
    ]);
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
        content: Text('This will add ${imported.length} template(s) to your list.'),
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
      setState(() {
        _templates.addAll(imported);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} template(s) imported')),
      );
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final data = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : await File(file.path!).readAsString();
    final allRows = const CsvToListConverter().convert(data.trim());
    try {
      final tpl = PackImportService.importFromCsv(
        csv: data,
        templateId: const Uuid().v4(),
        templateName: p.basenameWithoutExtension(file.name),
      );
      final exec = context.read<EvaluationExecutorService>();
      for (final spot in tpl.spots) {
        await exec.evaluateSingle(
          context,
          spot,
          template: tpl,
          anteBb: tpl.anteBb,
        );
      }
      final skipped = allRows.length - 1 - tpl.spots.length;
      setState(() {
        _templates.add(tpl);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${tpl.spots.length} spots${skipped > 0 ? ', $skipped skipped' : ''}'),
        ),
      );
      _edit(tpl);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid CSV')));
    }
  }

  Future<void> _pasteCsv() async {
    final clip = await Clipboard.getData('text/plain');
    final text = clip?.text?.trim();
    if (text == null || !text.startsWith('Title,HeroPosition')) return;
    final rows = const CsvToListConverter().convert(text);
    try {
      final tpl = PackImportService.importFromCsv(
        csv: text,
        templateId: const Uuid().v4(),
        templateName: 'Pasted Pack',
      );
      final exec = context.read<EvaluationExecutorService>();
      for (final spot in tpl.spots) {
        await exec.evaluateSingle(
          context,
          spot,
          template: tpl,
          anteBb: tpl.anteBb,
        );
      }
      final skipped = rows.length - 1 - tpl.spots.length;
      setState(() {
        _templates.add(tpl);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${tpl.spots.length} spots${skipped > 0 ? ', $skipped skipped' : ''}'),
        ),
      );
      _edit(tpl);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid CSV')));
    }
  }
}
