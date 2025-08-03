import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';

import '../services/cloud_training_history_service.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_pack_screen.dart';
import '../widgets/sync_status_widget.dart';

class CloudTrainingSessionDetailsScreen extends StatefulWidget {
  final CloudTrainingSession session;

  const CloudTrainingSessionDetailsScreen({super.key, required this.session});

  @override
  State<CloudTrainingSessionDetailsScreen> createState() =>
      _CloudTrainingSessionDetailsScreenState();
}

class _CloudTrainingSessionDetailsScreenState
    extends State<CloudTrainingSessionDetailsScreen> {
  static const _mistakesKey = 'cloud_session_mistakes_only';
  SharedPreferences? _prefs;
  bool _onlyErrors = false;
  late TextEditingController _commentController;
  String _comment = '';
  final Map<String, TextEditingController> _noteControllers = {};
  final Map<String, TextEditingController> _tagControllers = {};
  Map<String, String> _handNotes = {};
  Map<String, List<String>> _handTags = {};
  String _tagFilter = 'All';

  @override
  void initState() {
    super.initState();
    _comment = widget.session.comment ?? '';
    _commentController = TextEditingController(text: _comment);
    _handNotes = Map<String, String>.from(widget.session.handNotes ?? {});
    _handTags = {
      for (final e in widget.session.handTags?.entries ?? {})
        e.key: List<String>.from(e.value)
    };
    for (final r in widget.session.results) {
      _noteControllers[r.name] =
          TextEditingController(text: _handNotes[r.name] ?? '');
      _tagControllers[r.name] =
          TextEditingController(text: _handTags[r.name]?.join(', ') ?? '');
    }
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await PreferencesService.getInstance();
    setState(() {
      _prefs = prefs;
      _onlyErrors = prefs.getBool(_mistakesKey) ?? false;
    });
  }

  Future<void> _setMistakesOnly(bool v) async {
    final prefs = _prefs ?? await PreferencesService.getInstance();
    await prefs.setBool(_mistakesKey, v);
    setState(() => _onlyErrors = v);
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    for (final c in _tagControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveComment(String text) async {
    setState(() => _comment = text);
    final service = context.read<CloudTrainingHistoryService>();
    await service.updateSession(
      widget.session.path,
      data: text.trim().isEmpty
          ? {'comment': FieldValue.delete()}
          : {'comment': text.trim()},
    );
  }

  Future<void> _saveHandComment(String name, String text) async {
    _handNotes[name] = text;
    final service = context.read<CloudTrainingHistoryService>();
    final notes = {...?widget.session.handNotes};
    if (text.trim().isEmpty) {
      notes.remove(name);
      if (notes.isEmpty) {
        await service.updateSession(widget.session.path,
            data: {'handNotes': FieldValue.delete()});
        return;
      }
    } else {
      notes[name] = text.trim();
    }
    await service.updateSession(widget.session.path, handNotes: notes);
  }

  Future<void> _saveHandTags(String name, String text) async {
    final tags = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _handTags[name] = tags;
    final service = context.read<CloudTrainingHistoryService>();
    final map = {
      for (final e in widget.session.handTags?.entries ?? {})
        e.key: List<String>.from(e.value)
    };
    if (tags.isEmpty) {
      map.remove(name);
      if (map.isEmpty) {
        await service.updateSession(widget.session.path,
            data: {'handTags': FieldValue.delete()});
        return;
      }
    } else {
      map[name] = tags;
    }
    await service.updateSession(widget.session.path, handTags: map);
  }

  Future<void> _deleteSession(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Session?'),
          content: const Text('Are you sure you want to delete this session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await context
          .read<CloudTrainingHistoryService>()
          .deleteSession(widget.session.path);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    if (widget.session.results.isEmpty) return;
    final hands = context.read<SavedHandManagerService>().hands;
    final handMap = {for (final h in hands) h.name: h};
    final buffer = StringBuffer();
    for (final r in widget.session.results) {
      if (r.correct) continue;
      final hand = handMap[r.name];
      final gto = hand?.gtoAction;
      final group = hand?.rangeGroup;
      var line =
          '- ${r.name}: выбрано `${r.userAction}`, ожидалось `${r.expected}`';
      final extras = <String>[];
      if (gto != null && gto.isNotEmpty) extras.add('GTO: `$gto`');
      if (group != null && group.isNotEmpty) extras.add('группа: `$group`');
      if (extras.isNotEmpty) line += '. ${extras.join(', ')}';
      buffer.writeln(line);
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cloud_session.md');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'cloud_session.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: cloud_session.md')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (widget.session.results.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final hands = context.read<SavedHandManagerService>().hands;
    final handMap = {for (final h in hands) h.name: h};

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text('Training Session',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Incorrect Hands',
                style: pw.TextStyle(font: boldFont, fontSize: 18)),
            pw.SizedBox(height: 8),
            for (final r
                in widget.session.results.where((element) => !element.correct))
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(r.name, style: pw.TextStyle(font: boldFont)),
                    pw.Text('User: ${r.userAction}',
                        style: pw.TextStyle(font: regularFont)),
                    pw.Text('Expected: ${r.expected}',
                        style: pw.TextStyle(font: regularFont)),
                    if (handMap[r.name]?.gtoAction != null &&
                        handMap[r.name]!.gtoAction!.isNotEmpty)
                      pw.Text('GTO: ${handMap[r.name]!.gtoAction}',
                          style: pw.TextStyle(font: regularFont)),
                    if (handMap[r.name]?.rangeGroup != null &&
                        handMap[r.name]!.rangeGroup!.isNotEmpty)
                      pw.Text('Range: ${handMap[r.name]!.rangeGroup}',
                          style: pw.TextStyle(font: regularFont)),
                  ],
                ),
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cloud_session.pdf');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: cloud_session.pdf')),
      );
    }
  }

  Future<void> _exportJson(BuildContext context) async {
    final session = CloudTrainingSession(
      path: widget.session.path,
      date: widget.session.date,
      results: widget.session.results,
      comment: _comment.trim().isEmpty ? null : _comment.trim(),
      handNotes: _handNotes.isEmpty ? null : _handNotes,
      handTags: _handTags.isEmpty ? null : _handTags,
    );
    const encoder = JsonEncoder.withIndent('  ');
    final bytes = Uint8List.fromList(
      utf8.encode(encoder.convert(session.toJson())),
    );
    final name = 'session_${widget.session.date.millisecondsSinceEpoch}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'json',
        mimeType: MimeType.other,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл сохранён: $name.json')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка экспорта JSON')));
      }
    }
  }

  Future<void> _repeatSession(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final Map<String, SavedHand> map = {
      for (final h in manager.hands) h.name: h
    };
    final List<SavedHand> hands = [];
    for (final r in widget.session.results) {
      final hand = map[r.name];
      if (hand != null) hands.add(hand);
    }
    if (hands.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Раздачи не найдены')),
        );
      }
      return;
    }
    final pack = TrainingPack(
      name: 'Повторение',
      description: '',
      gameType: 'Cash Game',
      tags: const [],
      hands: hands,
      spots: const [],
      difficulty: 1,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(pack: pack, hands: hands),
      ),
    );
  }

  Future<void> _repeatErrors(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final Map<String, SavedHand> map = {
      for (final h in manager.hands) h.name: h
    };
    final List<SavedHand> hands = [];
    for (final r in widget.session.results) {
      if (r.correct) continue;
      final hand = map[r.name];
      if (hand != null) hands.add(hand);
    }
    if (hands.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Раздачи не найдены')),
        );
      }
      return;
    }
    final pack = TrainingPack(
      name: 'Повторение ошибок',
      description: '',
      gameType: 'Cash Game',
      tags: const [],
      hands: hands,
      spots: const [],
      difficulty: 1,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(pack: pack, hands: hands),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var results = _onlyErrors
        ? widget.session.results.where((r) => !r.correct).toList()
        : widget.session.results;
    if (_tagFilter != 'All') {
      results = [
        for (final r in results)
          if (_handTags[r.name]?.contains(_tagFilter) ?? false) r
      ];
    }
    final handMap = {
      for (final h in context.watch<SavedHandManagerService>().hands) h.name: h
    };
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${formatDate(widget.session.date)} • ${widget.session.accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Ошибки: ${widget.session.mistakes} из ${widget.session.total}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed: results.isEmpty ? null : () => _exportMarkdown(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF',
            onPressed: results.isEmpty ? null : () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: 'JSON',
            onPressed: results.isEmpty ? null : () => _exportJson(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () => _deleteSession(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: results.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _repeatSession(context),
                    child: const Text('Повторить'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: () => _repeatErrors(context),
                    child: const Text('Повторить ошибки'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Только ошибки',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: _onlyErrors,
                        onChanged: (v) => _setMistakesOnly(v),
                      ),
                    ],
                  ),
                ),
                if (_handTags.values.expand((e) => e).isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final t in {..._handTags.values.expand((e) => e)})
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(t),
                              selected: _tagFilter == t,
                              onSelected: (_) => setState(() =>
                                  _tagFilter = _tagFilter == t ? 'All' : t),
                            ),
                          ),
                        if (_tagFilter != 'All')
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.white70,
                            onPressed: () => setState(() => _tagFilter = 'All'),
                          ),
                      ],
                    ),
                  ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final r = results[index];
                      return Card(
                        color: const Color(0xFF2A2B2E),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          collapsedIconColor: Colors.white,
                          iconColor: Colors.white,
                          textColor: Colors.white,
                          collapsedTextColor: Colors.white,
                          leading: Icon(
                            r.correct ? Icons.check : Icons.close,
                            color: r.correct ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            r.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Вы: ${r.userAction}',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              Text('Ожидалось: ${r.expected}',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              if (_handTags[r.name]?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children: [
                                      for (final t in _handTags[r.name]!)
                                        Chip(
                                          label: Text(t),
                                          backgroundColor:
                                              const Color(0xFF3A3B3E),
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                () {
                                  final hand = handMap[r.name];
                                  if (hand == null) {
                                    return 'Раздача не найдена';
                                  }
                                  final gto = hand.gtoAction ?? r.expected;
                                  final group = hand.rangeGroup ?? '-';
                                  final verdict =
                                      r.correct ? 'верное' : 'ошибочное';
                                  return 'GTO предлагает $gto, ваша рука из группы $group. Это действие $verdict.';
                                }(),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: TextField(
                                controller: _noteControllers[r.name],
                                onChanged: (t) => _saveHandComment(r.name, t),
                                maxLines: null,
                                minLines: 2,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Заметка',
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: TextField(
                                controller: _tagControllers[r.name],
                                onChanged: (t) => _saveHandTags(r.name, t),
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Теги',
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _commentController,
                    onChanged: _saveComment,
                    maxLines: null,
                    minLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Комментарий',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
