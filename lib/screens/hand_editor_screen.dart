import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:poker_solver/hand.dart';
import '../widgets/poker_table_view.dart';
import '../widgets/card_picker_widget.dart';
import '../widgets/action_list_widget.dart';
import '../widgets/showdown_tab.dart';
import '../widgets/street_hud_bar.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../helpers/poker_position_helper.dart';
import '../services/hand_evaluator.dart';

class UndoIntent extends Intent { const UndoIntent(); }
class RedoIntent extends Intent { const RedoIntent(); }

class HandEditorScreen extends StatefulWidget {
  const HandEditorScreen({super.key});

  @override
  State<HandEditorScreen> createState() => _HandEditorScreenState();
}

class _HandSnapshot {
  final List<ActionEntry> pre, flop, turn, river;
  final List<double> stacks, bets;
  final double pot;
  final List<PlayerAction> actions;
  final List<List<CardModel>> revealed;
  final List<double> winnings;
  final List<double> spr, eff;
  const _HandSnapshot({
    required this.pre,
    required this.flop,
    required this.turn,
    required this.river,
    required this.stacks,
    required this.bets,
    required this.pot,
    required this.actions,
    required this.revealed,
    required this.winnings,
    required this.spr,
    required this.eff,
  });
}

class _HandEditorScreenState extends State<HandEditorScreen>
    with SingleTickerProviderStateMixin {
  final List<CardModel> _heroCards = [];
  final List<CardModel> _boardCards = [];
  final int _playerCount = 6;
  int _heroIndex = 0;
  final List<String> _names = [];
  late List<double> _initialStacks;
  List<ActionEntry> _preflopActions = [];
  List<ActionEntry> _flopActions = [];
  List<ActionEntry> _turnActions = [];
  List<ActionEntry> _riverActions = [];
  late List<double> _stacks;
  late List<PlayerAction> _actions;
  late List<double> _bets;
  late List<List<CardModel>> _revealedCards;
  late List<double> _winnings;
  late List<List<double>> _winParts;
  late List<double> _playerAllInAt;
  List<double> _streetSpr = List.filled(4, 0);
  List<double> _streetEff = List.filled(4, 0);
  List<double?> _streetPotOdds = List.filled(4, null);
  List<double?> _streetEv = List.filled(4, null);
  double _pot = 0;
  late TabController _tabController;
  final List<_HandSnapshot> _undo = [];
  final List<_HandSnapshot> _redo = [];
  bool _skipHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _names.addAll(List.generate(_playerCount, (i) => 'Player ${i + 1}'));
    _initialStacks = List.filled(_playerCount, 100.0);
    _stacks = List.from(_initialStacks);
    _actions = List.filled(_playerCount, PlayerAction.none);
    _bets = List.filled(_playerCount, 0.0);
    _revealedCards = List.generate(_playerCount, (_) => []);
    _winnings = List.filled(_playerCount, 0.0);
    _winParts = List.generate(_playerCount, (_) => []);
    _playerAllInAt = List.filled(_playerCount, double.infinity);
    _recompute();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recompute({bool pushHistory = true}) {
    final stacks = List<double>.from(_initialStacks);
    final actions = List.filled(_playerCount, PlayerAction.none);
    final bets = List.filled(_playerCount, 0.0);
    final allInAt = List<double>.filled(_playerCount, double.infinity);
    double pot = 0;
    final spr = List<double>.filled(4, 0);
    final eff = List<double>.filled(4, 0);
    final heroPo = List<double?>.filled(4, null);
    final heroEv = List<double?>.filled(4, null);
    int street = 0;
    void apply(List<ActionEntry> list) {
      for (var i = 0; i < list.length; i++) {
        final a = list[i];
        final prevBet = bets[a.playerIndex];
        switch (a.action) {
          case 'fold':
            actions[a.playerIndex] = PlayerAction.fold;
            break;
          case 'post':
            final amt = (a.amount ?? 0).toDouble();
            stacks[a.playerIndex] -= amt;
            bets[a.playerIndex] = amt;
            pot += amt;
            actions[a.playerIndex] = PlayerAction.post;
            break;
          case 'call':
            final amt = (a.amount ?? 0).toDouble();
            final diff = amt - bets[a.playerIndex];
            if (diff > 0) {
              stacks[a.playerIndex] -= diff;
              pot += diff;
            }
            bets[a.playerIndex] = amt;
            actions[a.playerIndex] = PlayerAction.call;
            break;
          case 'raise':
            final amt = (a.amount ?? 0).toDouble();
            final diff = amt - bets[a.playerIndex];
            if (diff > 0) {
              stacks[a.playerIndex] -= diff;
              pot += diff;
            }
            bets[a.playerIndex] = amt;
            actions[a.playerIndex] = PlayerAction.raise;
            break;
          case 'push':
            final amt = (a.amount ?? 0).toDouble();
            allInAt[a.playerIndex] = bets[a.playerIndex] + stacks[a.playerIndex];
            final diff = amt - bets[a.playerIndex];
            if (diff > 0) {
              stacks[a.playerIndex] -= diff;
              pot += diff;
            }
            bets[a.playerIndex] = amt;
            actions[a.playerIndex] = PlayerAction.push;
            break;
        }
        var updated = a.copyWith(potAfter: pot);
        if (a.playerIndex == _heroIndex &&
            (a.action == 'call' || a.action == 'push')) {
          final toCall =
              (bets[a.playerIndex] - prevBet).clamp(0, double.infinity);
          final potOdds = toCall == 0 ? null : (toCall / pot * 100);
          heroPo[street] = potOdds;
          final potAfter = pot;
          final ev = a.equity == null
              ? null
              : (a.equity! / 100) * (potAfter) - toCall;
          heroEv[street] = ev;
          updated =
              updated.copyWith(potOdds: potOdds, ev: ev);
        } else {
          updated = updated.copyWith(potOdds: null, ev: null);
        }
        list[i] = updated;
      }
    }

    for (final list in [
      _preflopActions,
      _flopActions,
      _turnActions,
      _riverActions
    ]) {
      apply(list);
      final active = [
        for (int i = 0; i < _playerCount; i++)
          if (actions[i] != PlayerAction.fold) i
      ];
      if (active.isNotEmpty) {
        final effStack = active.map((i) => stacks[i]).reduce(math.min);
        eff[street] = effStack;
        spr[street] = effStack / math.max(pot, 0.01);
      }
      street++;
    }

    setState(() {
      _stacks = stacks;
      _actions = actions;
      _bets = bets;
      _pot = pot;
      _playerAllInAt = allInAt;
      _streetSpr = spr;
      _streetEff = eff;
      _streetPotOdds = heroPo;
      _streetEv = heroEv;
    });
    if (pushHistory && !_skipHistory) _pushHistory();
  }

  _HandSnapshot _makeSnapshot() => _HandSnapshot(
        pre: [for (final a in _preflopActions) _copyAction(a)],
        flop: [for (final a in _flopActions) _copyAction(a)],
        turn: [for (final a in _turnActions) _copyAction(a)],
        river: [for (final a in _riverActions) _copyAction(a)],
        stacks: List<double>.from(_stacks),
        bets: List<double>.from(_bets),
        pot: _pot,
        actions: List<PlayerAction>.from(_actions),
        revealed: [
          for (final r in _revealedCards)
            [for (final c in r) CardModel(rank: c.rank, suit: c.suit)]
        ],
        winnings: List<double>.from(_winnings),
        spr: List<double>.from(_streetSpr),
        eff: List<double>.from(_streetEff),
      );

  ActionEntry _copyAction(ActionEntry a) => ActionEntry(
        a.street,
        a.playerIndex,
        a.action,
        amount: a.amount,
        generated: a.generated,
        manualEvaluation: a.manualEvaluation,
        customLabel: a.customLabel,
        timestamp: a.timestamp,
        potAfter: a.potAfter,
        potOdds: a.potOdds,
        equity: a.equity,
        ev: a.ev,
      );

  void _pushHistory() {
    _undo.add(_makeSnapshot());
    _redo.clear();
    if (_undo.length > 50) _undo.removeAt(0);
  }

  bool get _canUndo => _undo.isNotEmpty;
  bool get _canRedo => _redo.isNotEmpty;

  void _undoAction() {
    if (_canUndo) {
      _redo.add(_makeSnapshot());
      _applySnapshot(_undo.removeLast());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undo')),
      );
    }
  }

  void _redoAction() {
    if (_canRedo) {
      _undo.add(_makeSnapshot());
      _applySnapshot(_redo.removeLast());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redo')),
      );
    }
  }

  void _applySnapshot(_HandSnapshot s) {
    _skipHistory = true;
    setState(() {
      _preflopActions = [for (final a in s.pre) _copyAction(a)];
      _flopActions = [for (final a in s.flop) _copyAction(a)];
      _turnActions = [for (final a in s.turn) _copyAction(a)];
      _riverActions = [for (final a in s.river) _copyAction(a)];
      _stacks = List<double>.from(s.stacks);
      _bets = List<double>.from(s.bets);
      _pot = s.pot;
      _actions = List<PlayerAction>.from(s.actions);
      _streetSpr = List<double>.from(s.spr);
      _streetEff = List<double>.from(s.eff);
      _revealedCards = [
        for (final r in s.revealed)
          [for (final c in r) CardModel(rank: c.rank, suit: c.suit)]
      ];
      _winnings = List<double>.from(s.winnings);
      _winParts = List.generate(_playerCount, (_) => []);
      _recompute(pushHistory: false);
    });
    _skipHistory = false;
  }

  Map<String, dynamic> _toJson() => {
        'heroIndex': _heroIndex,
        'names': _names,
        'initialStacks': _initialStacks,
        'heroCards': [
          for (final c in _heroCards) {'r': c.rank, 's': c.suit}
        ],
        'boardCards': [
          for (final c in _boardCards) {'r': c.rank, 's': c.suit}
        ],
        'preflop': [_forJson(_preflopActions)],
        'flop': [_forJson(_flopActions)],
        'turn': [_forJson(_turnActions)],
        'river': [_forJson(_riverActions)],
        'revealed': [
          for (final r in _revealedCards)
            [for (final c in r) {'r': c.rank, 's': c.suit}]
        ],
        'winnings': _winnings,
      };

  List<Map<String, dynamic>> _forJson(List<ActionEntry> list) => [
        for (final a in list)
          {
            'st': a.street,
            'p': a.playerIndex,
            'a': a.action,
            if (a.amount != null) 'amt': a.amount,
            if (a.customLabel != null) 'lbl': a.customLabel,
            'pa': a.potAfter,
            if (a.potOdds != null) 'po': a.potOdds,
            if (a.equity != null) 'eq': a.equity,
            if (a.ev != null) 'ev': a.ev,
          }
      ];

  void _applyFromJson(Map<String, dynamic> json) {
    _heroCards
      ..clear()
      ..addAll([
        for (final c in (json['heroCards'] as List? ?? []))
          if (c is Map)
            CardModel(rank: c['r'] as String, suit: c['s'] as String)
      ]);
    _boardCards
      ..clear()
      ..addAll([
        for (final c in (json['boardCards'] as List? ?? []))
          if (c is Map)
            CardModel(rank: c['r'] as String, suit: c['s'] as String)
      ]);
    _heroIndex = json['heroIndex'] as int? ?? 0;
    _names
      ..clear()
      ..addAll([for (final n in (json['names'] as List? ?? [])) n as String]);
    _initialStacks = [
      for (final s in (json['initialStacks'] as List? ?? []))
        (s as num).toDouble()
    ];
    List<ActionEntry> parse(List? list) => [
          for (final a in (list ?? []))
            if (a is Map)
              ActionEntry(
                a['st'] as int? ?? 0,
                a['p'] as int? ?? 0,
                a['a'] as String? ?? '',
                amount: (a['amt'] as num?)?.toDouble(),
                customLabel: a['lbl'] as String?,
                potAfter: (a['pa'] as num?)?.toDouble() ?? 0,
                potOdds: (a['po'] as num?)?.toDouble(),
                equity: (a['eq'] as num?)?.toDouble(),
                ev: (a['ev'] as num?)?.toDouble(),
              )
        ];
    _preflopActions = parse(json['preflop']);
    _flopActions = parse(json['flop']);
    _turnActions = parse(json['turn']);
    _riverActions = parse(json['river']);
    _revealedCards = [
      for (final r in (json['revealed'] as List? ?? []))
        [
          for (final c in (r as List? ?? []))
            if (c is Map) CardModel(rank: c['r'] as String, suit: c['s'] as String)
        ]
    ];
    if (_revealedCards.length < _playerCount) {
      _revealedCards.addAll(
          List.generate(_playerCount - _revealedCards.length, (_) => []));
    }
    _winnings = [
      for (final w in (json['winnings'] as List? ?? [])) (w as num).toDouble()
    ];
    if (_winnings.length < _playerCount) {
      _winnings.addAll(List.filled(_playerCount - _winnings.length, 0.0));
    }
    setState(() {
      _recompute(pushHistory: false);
    });
    _undo.clear();
    _redo.clear();
    _pushHistory();
  }

  Future<void> _exportJson() async {
    final jsonStr = jsonEncode(_toJson());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hand copied to clipboard')),
    );
  }

  Future<void> _importJson() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.trim().isEmpty) return;
    try {
      _applyFromJson(Map<String, dynamic>.from(jsonDecode(data.text!)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hand loaded')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON')),
      );
    }
  }

  void _onPreflopChanged(List<ActionEntry> list) {
    setState(() {
      _preflopActions = list;
      _recompute();
    });
  }

  void _onFlopChanged(List<ActionEntry> list) {
    setState(() {
      _flopActions = list;
      _recompute();
    });
  }

  void _onTurnChanged(List<ActionEntry> list) {
    setState(() {
      _turnActions = list;
      _recompute();
    });
  }

  void _onRiverChanged(List<ActionEntry> list) {
    setState(() {
      _riverActions = list;
      _recompute();
    });
  }

  Set<String> get _usedCards => {
        for (final c in _heroCards) '${c.rank}${c.suit}',
        for (final c in _boardCards) '${c.rank}${c.suit}',
        for (final r in _revealedCards) for (final c in r) '${c.rank}${c.suit}',
      };

  void _setBoardCard(int index, CardModel card) {
    setState(() {
      if (_boardCards.length > index) {
        _boardCards[index] = card;
      } else if (_boardCards.length == index) {
        _boardCards.add(card);
      }
    });
  }

  void _nextStreet() {
    final current = _tabController.index;
    if (current < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stakes committed — moving to ${['Flop', 'Turn', 'River', 'Showdown'][current + 1]}'),
        ),
      );
      setState(() {
        for (int i = 0; i < _playerCount; i++) {
          _pot += _bets[i];
          _bets[i] = 0;
        }
        _actions = List.filled(_playerCount, PlayerAction.none);
        _recompute();
      });
      _tabController.animateTo(current + 1);
    }
  }

  Future<void> _revealCards() async {
    int idx = 0;
    List<CardModel> cards = List.from(_revealedCards[0]);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          title: const Text('Reveal', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: idx,
                dropdownColor: const Color(0xFF2A2B2E),
                underline: const SizedBox.shrink(),
                items: [
                  for (int i = 0; i < _playerCount; i++)
                    DropdownMenuItem(value: i, child: Text('Player ${i + 1}'))
                ],
                onChanged: (v) => setState(() {
                  idx = v ?? 0;
                  cards = List.from(_revealedCards[idx]);
                }),
              ),
              const SizedBox(height: 8),
              CardPickerWidget(
                cards: cards,
                count: 2,
                onChanged: (i, c) => setState(() {
                  if (cards.length > i) {
                    cards[i] = c;
                  } else if (cards.length == i) {
                    cards.add(c);
                  }
                }),
                disabledCards: _usedCards,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, {'idx': idx, 'cards': cards}),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _revealedCards[result['idx'] as int] =
            List<CardModel>.from(result['cards'] as List<CardModel>);
      });
      _pushHistory();
    }
  }

  Future<void> _distributePot() async {
    final controllers =
        List.generate(_playerCount, (i) => TextEditingController(text: '0'));
    final result = await showDialog<List<double>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        title: const Text('Distribute', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_playerCount, (i) {
            return TextField(
              controller: controllers[i],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Player ${i + 1}',
                labelStyle: const TextStyle(color: Colors.white54),
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              [
                for (final c in controllers)
                  double.tryParse(c.text) ?? 0.0
              ],
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        for (int i = 0; i < _playerCount; i++) {
          _winnings[i] = result[i];
          _stacks[i] += _winnings[i];
        }
        _winParts = List.generate(_playerCount, (_) => []);
        _pot = 0;
      });
      _pushHistory();
    }
  }

  void _autoShowdown() {
    final hands = HandEvaluator.buildHands(_revealedCards, _boardCards);
    if (hands.length < 2) return;
    final wins = HandEvaluator.splitWithSidePots(
      showdownHands: hands,
      bets: _bets,
      allInAt: _playerAllInAt,
      mainPot: _pot,
    );
    final breakdown = List.generate(_playerCount, (_) => <double>[]);
    final levels = [
      for (final v in _playerAllInAt)
        if (v.isFinite) v
    ]..sort();
    double remaining = _pot;
    double prev = 0;
    final Set<int> active = hands.keys.toSet();
    for (final level in levels) {
      final participants = [
        for (int i = 0; i < _playerCount; i++)
          if (_playerAllInAt[i] >= level || !_playerAllInAt[i].isFinite) i
      ];
      double pot = (level - prev) * participants.length;
      if (pot > remaining) pot = remaining;
      final eligibles = [
        for (final p in participants)
          if (hands.containsKey(p)) p
      ];
      if (pot > 0 && eligibles.isNotEmpty) {
        final hs = {for (final p in eligibles) p: hands[p]!};
        final winners = Hand.winners(hs.values.toList());
        final share = pot / winners.length;
        for (final e in hs.entries) {
          if (winners.contains(e.value)) {
            breakdown[e.key].add(share);
          }
        }
      }
      remaining -= pot;
      active.removeWhere((p) => _playerAllInAt[p] == level);
      prev = level;
      if (remaining <= 0) break;
    }
    if (remaining > 0 && active.isNotEmpty) {
      final hs = {for (final p in active) p: hands[p]!};
      final winners = Hand.winners(hs.values.toList());
      final share = remaining / winners.length;
      for (final e in hs.entries) {
        if (winners.contains(e.value)) {
          breakdown[e.key].add(share);
        }
      }
    }
    setState(() {
      for (int i = 0; i < _playerCount; i++) {
        _winnings[i] = wins[i] ?? 0;
        _stacks[i] += _winnings[i];
      }
      _winParts = breakdown;
      _pot = 0;
    });
    _pushHistory();
  }

  Widget _buildBoardRow() {
    final cards =
        List.generate(5, (i) => i < _boardCards.length ? _boardCards[i] : null);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards.map((c) {
          final isRed = c?.suit == '♥' || c?.suit == '♦';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 36,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: c == null ? 0.3 : 1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(1, 2),
                )
              ],
            ),
            alignment: Alignment.center,
            child: c != null
                ? Text(
                    '${c.rank}${c.suit}',
                    style: TextStyle(
                      color: isRed ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : const Icon(Icons.add, color: Colors.grey),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreetPicker(int start, int count) {
    final end = (_boardCards.length - start).clamp(0, count);
    final cards = end > 0
        ? _boardCards.sublist(start, start + end)
        : <CardModel>[];
    return CardPickerWidget(
      cards: cards,
      count: count,
      onChanged: (i, c) => _setBoardCard(start + i, c),
      disabledCards: _usedCards,
    );
  }

  void _editPlayers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _playerCount,
          separatorBuilder: (_, __) => const Divider(color: Colors.white24),
          itemBuilder: (context, i) {
            final nameController = TextEditingController(text: _names[i]);
            final stackController =
                TextEditingController(text: _initialStacks[i].toString());
            return Row(
              children: [
                SizedBox(width: 20, child: Text('$i', style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (v) {
                      setState(() {
                        _names[i] = v;
                      });
                      _recompute();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: stackController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Stack BB'),
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val == null || val < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter valid stack')),
                        );
                        return;
                      }
                      setState(() {
                        _initialStacks[i] = val;
                      });
                      _recompute();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const RedoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _undoAction()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => _redoAction()),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
          appBar: AppBar(
            title: const Text('Hand Editor'),
            actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _canUndo ? _undoAction : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _canRedo ? _redoAction : null,
          ),
          TextButton(
            onPressed: _editPlayers,
            child: const Text('📝 Players'),
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportJson),
          FutureBuilder<ClipboardData?>(
            future: Clipboard.getData('text/plain'),
            builder: (context, snapshot) {
              final hasText = snapshot.data?.text?.trim().isNotEmpty ?? false;
              return IconButton(
                icon: const Icon(Icons.upload),
                onPressed: hasText ? _importJson : null,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed:
                _tabController.index == 4 ? _revealCards : null,
          ),
          TextButton(
            onPressed: _tabController.index == 4 &&
                    _boardCards.length >= 5 &&
                    _revealedCards.where((c) => c.length == 2).length >= 2
                ? _autoShowdown
                : null,
            child: const Text('🧠 Auto'),
          ),
          IconButton(
            icon: const Icon(Icons.paid),
            onPressed:
                _tabController.index == 4 ? _distributePot : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _tabController.index >= 4 ? null : _nextStreet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Preflop'),
            Tab(text: 'Flop'),
            Tab(text: 'Turn'),
            Tab(text: 'River'),
            Tab(text: 'Showdown'),
          ],
        ),
      ),
      body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButton<int>(
                value: _heroIndex,
                underline: const SizedBox.shrink(),
                items: [
                  for (int i = 0; i < _playerCount; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(getPositionList(_playerCount)[i]),
                    )
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _heroIndex = v;
                  _recompute();
                },
              ),
            ),
            IgnorePointer(
              child: PokerTableView(
                heroIndex: _heroIndex,
                playerCount: _playerCount,
                playerNames: _names,
                playerStacks: _stacks,
                playerActions: _actions,
                playerBets: _bets,
                onHeroSelected: (_) {},
                onStackChanged: (_, __) {},
                onNameChanged: (_, __) {},
                onBetChanged: (_, __) {},
              onActionChanged: (_, __) {},
              potSize: _pot,
              onPotChanged: (_) {},
              heroCards: _heroCards,
              revealedCards: _revealedCards,
              boardCards: _boardCards,
              currentStreet: _tabController.index.clamp(0, 3),
              showPlayerActions: true,
              ),
            ),
            _buildBoardRow(),
            StreetHudBar(
              spr: _streetSpr,
              eff: _streetEff,
              potOdds: _streetPotOdds,
              ev: _streetEv,
              currentStreet: _tabController.index.clamp(0, 3),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CardPickerWidget(
                          cards: _heroCards,
                          onChanged: (i, c) {
                            setState(() {
                              if (_heroCards.length > i) {
                                _heroCards[i] = c;
                              } else {
                                _heroCards.add(c);
                              }
                            });
                          },
                          disabledCards: _usedCards,
                        ),
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          heroIndex: _heroIndex,
                          initial: _preflopActions,
                          showPot: true,
                          currentStacks: _stacks,
                          onChanged: _onPreflopChanged,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStreetPicker(0, 3),
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          heroIndex: _heroIndex,
                          initial: _flopActions,
                          showPot: true,
                          currentStacks: _stacks,
                          onChanged: _onFlopChanged,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStreetPicker(3, 1),
                        const SizedBox(height: 12),
                        ActionListWidget(
                          playerCount: _playerCount,
                          heroIndex: _heroIndex,
                          initial: _turnActions,
                          showPot: true,
                          currentStacks: _stacks,
                          onChanged: _onTurnChanged,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStreetPicker(4, 1),
                    const SizedBox(height: 12),
                    ActionListWidget(
                      playerCount: _playerCount,
                      heroIndex: _heroIndex,
                      initial: _riverActions,
                      showPot: true,
                      currentStacks: _stacks,
                      onChanged: _onRiverChanged,
                    ),
                  ],
                ),
              ),
              ShowdownTab(
                names: _names,
                revealed: _revealedCards,
                stacks: _stacks,
                winnings: _winnings,
                parts: _winParts,
                pot: _pot,
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
