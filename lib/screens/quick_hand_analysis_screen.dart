import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../widgets/card_picker_widget.dart';
import '../services/hand_analysis_history_service.dart';
import '../models/hand_analysis_record.dart';
import '../services/hand_analyzer_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/adaptive_training_service.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';
import '../models/v2/training_pack_template.dart';
import '../theme/app_colors.dart';

class QuickHandAnalysisScreen extends StatefulWidget {
  final HandAnalysisRecord? record;
  const QuickHandAnalysisScreen({super.key, this.record});

  @override
  State<QuickHandAnalysisScreen> createState() =>
      _QuickHandAnalysisScreenState();
}

class _QuickHandAnalysisScreenState extends State<QuickHandAnalysisScreen> {
  final _stackController = TextEditingController(text: '10');
  final _players = [2, 3, 4, 5, 6, 7, 8, 9];
  int _playerCount = 6;
  int _heroIndex = 0;
  List<CardModel> _cards = [];
  double? _ev;
  double? _icm;
  String? _action;
  String? _hint;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    if (r != null) {
      _stackController.text = r.stack.toString();
      _playerCount = r.playerCount;
      _heroIndex = r.heroIndex;
      _cards = r.cards;
      _ev = r.ev;
      _icm = r.icm;
      _action = r.action;
      _hint = r.hint;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _stackController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final stack = int.tryParse(_stackController.text) ?? 10;
    final level = context.read<XPTrackerService>().level;
    final record = context.read<HandAnalyzerService>().analyzePush(
      cards: _cards,
      stack: stack,
      playerCount: _playerCount,
      heroIndex: _heroIndex,
      level: level,
    );
    if (record == null) return;
    setState(() {
      _ev = record.ev;
      _icm = record.icm;
      _action = record.action;
      _hint = record.hint;
    });
  }

  void _scheduleAnalysis() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _analyze);
  }

  Future<void> _save() async {
    final stack = int.tryParse(_stackController.text) ?? 10;
    final level = context.read<XPTrackerService>().level;
    final record = context.read<HandAnalyzerService>().analyzePush(
      cards: _cards,
      stack: stack,
      playerCount: _playerCount,
      heroIndex: _heroIndex,
      level: level,
    );
    if (record == null) return;
    context.read<HandAnalysisHistoryService>().add(record);
    setState(() {
      _ev = record.ev;
      _icm = record.icm;
      _action = record.action;
      _hint = record.hint;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Быстрый анализ')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Карты героя', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            CardPickerWidget(
              cards: _cards,
              onChanged: (i, c) {
                setState(() {
                  if (_cards.length > i) {
                    _cards[i] = c;
                  } else {
                    _cards.add(c);
                  }
                });
                _scheduleAnalysis();
              },
              disabledCards: const {},
            ),
            const SizedBox(height: 16),
            const Text('Позиция', style: TextStyle(color: Colors.white)),
            DropdownButton<int>(
              value: _heroIndex,
              dropdownColor: Colors.black,
              items: List.generate(
                _playerCount,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    'P${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              onChanged: (v) {
                setState(() => _heroIndex = v ?? 0);
                _scheduleAnalysis();
              },
            ),
            const SizedBox(height: 16),
            const Text('Стек (BB)', style: TextStyle(color: Colors.white)),
            TextField(
              controller: _stackController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => _scheduleAnalysis(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Количество игроков',
              style: TextStyle(color: Colors.white),
            ),
            DropdownButton<int>(
              value: _playerCount,
              dropdownColor: Colors.black,
              items: _players
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        '$e',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _playerCount = v ?? 6;
                  if (_heroIndex >= _playerCount) _heroIndex = 0;
                });
                _scheduleAnalysis();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить'),
              ),
            ),
            const SizedBox(height: 24),
            if (_ev != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EV: ${_ev!.toStringAsFixed(2)} BB',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'ICM: ${_icm!.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Решение: $_action',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_hint != null)
                    Text(_hint!, style: const TextStyle(color: Colors.white70)),
                  ValueListenableBuilder<List<TrainingPackTemplate>>(
                    valueListenable: context
                        .read<AdaptiveTrainingService>()
                        .recommendedNotifier,
                    builder: (_, list, __) {
                      if (list.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Рекомендуемые паки:',
                            style: TextStyle(color: Colors.white),
                          ),
                          for (final t in list.take(3))
                            TextButton(
                              onPressed: () async {
                                await context
                                    .read<TrainingSessionService>()
                                    .startSession(t);
                                if (context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TrainingSessionScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Text(t.name),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
