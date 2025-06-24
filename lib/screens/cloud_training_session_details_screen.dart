import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_pack_screen.dart';

class CloudTrainingSessionDetailsScreen extends StatefulWidget {
  final CloudTrainingSession session;

  const CloudTrainingSessionDetailsScreen({super.key, required this.session});

  @override
  State<CloudTrainingSessionDetailsScreen> createState() =>
      _CloudTrainingSessionDetailsScreenState();
}

class _CloudTrainingSessionDetailsScreenState
    extends State<CloudTrainingSessionDetailsScreen> {
  bool _onlyErrors = false;
  late TextEditingController _commentController;
  String _comment = '';

  @override
  void initState() {
    super.initState();
    _comment = widget.session.comment ?? '';
    _commentController = TextEditingController(text: _comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveComment(String text) async {
    setState(() => _comment = text);
    final file = File(widget.session.path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      Map<String, dynamic> map;
      if (data is Map<String, dynamic>) {
        map = Map<String, dynamic>.from(data);
      } else if (data is List) {
        map = {
          'results': data,
          'date': widget.session.date.toIso8601String(),
        };
      } else {
        return;
      }
      if (text.trim().isEmpty) {
        map.remove('comment');
      } else {
        map['comment'] = text.trim();
      }
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (_) {}
  }

  Future<void> _deleteSession(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Session?'),
          content:
              const Text('Are you sure you want to delete this session?'),
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
      final file = File(widget.session.path);
      if (await file.exists()) {
        await file.delete();
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    if (widget.session.results.isEmpty) return;
    final buffer = StringBuffer();
    for (final r in widget.session.results) {
      final result = r.correct ? 'correct' : 'wrong';
      buffer.writeln(
          '- ${r.name}: user `${r.userAction}`, expected `${r.expected}` - $result');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cloud_session.md');
    await file.writeAsString(buffer.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: cloud_session.md')),
      );
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
      hands: hands,
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
    final results = _onlyErrors
        ? widget.session.results.where((r) => !r.correct).toList()
        : widget.session.results;
    return Scaffold(
      appBar: AppBar(
        title: Text(formatDateTime(widget.session.date)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed:
                results.isEmpty ? null : () => _exportMarkdown(context),
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
                        onChanged: (v) => setState(() => _onlyErrors = v),
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
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2B2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              r.correct ? Icons.check : Icons.close,
                              color: r.correct ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Вы: ${r.userAction}',
                                      style:
                                          const TextStyle(color: Colors.white70)),
                                  Text('Ожидалось: ${r.expected}',
                                      style:
                                          const TextStyle(color: Colors.white70)),
                                ],
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
