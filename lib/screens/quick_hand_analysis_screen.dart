import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../widgets/card_picker_widget.dart';
import '../services/push_fold_ev_service.dart';
import '../services/hand_analysis_history_service.dart';
import '../models/hand_analysis_record.dart';
import '../theme/app_colors.dart';
import '../helpers/hand_utils.dart';

class QuickHandAnalysisScreen extends StatefulWidget {
  final HandAnalysisRecord? record;
  const QuickHandAnalysisScreen({super.key, this.record});

  @override
  State<QuickHandAnalysisScreen> createState() => _QuickHandAnalysisScreenState();
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
    }
  }

  @override
  void dispose() {
    _stackController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_cards.length < 2) return;
    final hand = handCode('${_cards[0].rank}${_cards[0].suit} ${_cards[1].rank}${_cards[1].suit}');
    if (hand == null) return;
    final stack = int.tryParse(_stackController.text) ?? 10;
    final ev = computePushEV(heroBbStack: stack, bbCount: _playerCount - 1, heroHand: hand, anteBb: 0);
    final stacks = List.filled(_playerCount, stack);
    final icm = computeIcmPushEV(chipStacksBb: stacks, heroIndex: _heroIndex, heroHand: hand, chipPushEv: ev);
    final action = ev >= 0 ? 'push' : 'fold';
    context.read<HandAnalysisHistoryService>().add(
          HandAnalysisRecord(
            card1: '${_cards[0].rank}${_cards[0].suit}',
            card2: '${_cards[1].rank}${_cards[1].suit}',
            stack: stack,
            playerCount: _playerCount,
            heroIndex: _heroIndex,
            ev: ev,
            icm: icm,
            action: action,
          ),
        );
    setState(() {
      _ev = ev;
      _icm = icm;
      _action = action;
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
            CardPickerWidget(cards: _cards, onChanged: (i, c) { setState(() {
              if (_cards.length > i) {
                _cards[i] = c;
              } else {
                _cards.add(c);
              }
            }); }, disabledCards: const {},),
            const SizedBox(height: 16),
            const Text('Позиция', style: TextStyle(color: Colors.white)),
            DropdownButton<int>(
              value: _heroIndex,
              dropdownColor: Colors.black,
              items: List.generate(_playerCount, (i) => DropdownMenuItem(value: i, child: Text('P${i + 1}', style: const TextStyle(color: Colors.white)))),
              onChanged: (v) => setState(() => _heroIndex = v ?? 0),
            ),
            const SizedBox(height: 16),
            const Text('Стек (BB)', style: TextStyle(color: Colors.white)),
            TextField(
              controller: _stackController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Количество игроков', style: TextStyle(color: Colors.white)),
            DropdownButton<int>(
              value: _playerCount,
              dropdownColor: Colors.black,
              items: _players.map((e) => DropdownMenuItem(value: e, child: Text('$e', style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setState(() { _playerCount = v ?? 6; if (_heroIndex >= _playerCount) _heroIndex = 0; }),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _analyze,
                child: const Text('Анализировать'),
              ),
            ),
            const SizedBox(height: 24),
            if (_ev != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EV: ${_ev!.toStringAsFixed(2)} BB', style: const TextStyle(color: Colors.white)),
                  Text('ICM: ${_icm!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                  Text('Решение: $_action', style: const TextStyle(color: Colors.white)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
