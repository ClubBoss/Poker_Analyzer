import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/poker_table_view.dart';
import '../models/table_state.dart';
import '../services/table_edit_history.dart';

class PokerTableDemoScreen extends StatefulWidget {
  const PokerTableDemoScreen({super.key});

  @override
  State<PokerTableDemoScreen> createState() => _PokerTableDemoScreenState();
}

class _PokerTableDemoScreenState extends State<PokerTableDemoScreen> {
  int _playerCount = 6;
  late List<String> _names;
  late List<double> _stacks;
  late List<PlayerAction> _actions;
  late List<double> _bets;
  int _heroIndex = 0;
  double _pot = 0.0;
  TableTheme _theme = TableTheme.dark;
  final _history = TableEditHistory();

  TableState get _state => TableState(
        playerCount: _playerCount,
        names: List<String>.from(_names),
        stacks: List<double>.from(_stacks),
        heroIndex: _heroIndex,
        pot: _pot,
      );

  @override
  void initState() {
    super.initState();
    _reset();
    _history.clear();
  }

  void _reset() {
    _names = List.generate(_playerCount, (i) => 'Player ${i + 1}');
    _stacks = List.filled(_playerCount, 0.0);
    _actions = List.filled(_playerCount, PlayerAction.none);
    _bets = List.filled(_playerCount, 0.0);
    _heroIndex = 0;
    _pot = 0.0;
  }

  void _changeCount(int delta) {
    _history.push(_state);
    setState(() {
      _playerCount = (_playerCount + delta).clamp(2, 10);
      if (_names.length < _playerCount) {
        final start = _names.length;
        _names.addAll(
          List.generate(_playerCount - start, (i) => 'Player ${start + i + 1}'),
        );
      } else if (_names.length > _playerCount) {
        _names = _names.sublist(0, _playerCount);
      }
      if (_stacks.length < _playerCount) {
        _stacks.addAll(List.filled(_playerCount - _stacks.length, 0.0));
      } else if (_stacks.length > _playerCount) {
        _stacks = _stacks.sublist(0, _playerCount);
      }
      if (_bets.length < _playerCount) {
        _bets.addAll(List.filled(_playerCount - _bets.length, 0.0));
      } else if (_bets.length > _playerCount) {
        _bets = _bets.sublist(0, _playerCount);
      }
      if (_actions.length < _playerCount) {
        _actions.addAll(
          List.filled(_playerCount - _actions.length, PlayerAction.none),
        );
      } else if (_actions.length > _playerCount) {
        _actions = _actions.sublist(0, _playerCount);
      }
      if (_heroIndex >= _playerCount) _heroIndex = _playerCount - 1;
    });
  }

  void _clear() => setState(_reset);

  void _nextTheme() {
    setState(() {
      const values = TableTheme.values;
      _theme = values[(_theme.index + 1) % values.length];
    });
  }

  void _applyState(TableState s) {
    setState(() {
      _playerCount = s.playerCount;
      _names = List<String>.from(s.names);
      _stacks = List<double>.from(s.stacks);
      _actions = List.filled(_playerCount, PlayerAction.none);
      _bets = List.filled(_playerCount, 0.0);
      _heroIndex = s.heroIndex;
      _pot = s.pot;
    });
  }

  void _undo() {
    final s = _history.undo(_state);
    if (s != null) _applyState(s);
  }

  void _redo() {
    final s = _history.redo(_state);
    if (s != null) _applyState(s);
  }

  void _resetActions() => setState(() {
        _actions = List.filled(_playerCount, PlayerAction.none);
        _bets = List.filled(_playerCount, 0.0);
      });

  Future<void> _copyJson() async {
    final jsonStr = jsonEncode(_state.toJson());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Table copied')));
    }
  }

  Future<void> _pasteJson() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    try {
      final json = jsonDecode(text);
      final state = TableState.fromJson(Map<String, dynamic>.from(json as Map));
      _applyState(state);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table pasted')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Invalid JSON'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Table Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _history.canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _history.canRedo ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyJson,
            tooltip: 'Copy JSON',
          ),
          IconButton(
            icon: const Icon(Icons.paste),
            onPressed: _pasteJson,
            tooltip: 'Paste JSON',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetActions),
          IconButton(icon: const Icon(Icons.color_lens), onPressed: _nextTheme),
          IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokerTableView(
              heroIndex: _heroIndex,
              playerCount: _playerCount,
              playerNames: _names,
              playerStacks: _stacks,
              playerActions: _actions,
              playerBets: _bets,
              onHeroSelected: (i) {
                _history.push(_state);
                setState(() => _heroIndex = i);
              },
              onStackChanged: (i, v) {
                _history.push(_state);
                setState(() => _stacks[i] = v);
              },
              onNameChanged: (i, v) {
                _history.push(_state);
                setState(() => _names[i] = v);
              },
              onBetChanged: (i, v) => setState(() => _bets[i] = v),
              onActionChanged: (i, a) => setState(() => _actions[i] = a),
              potSize: _pot,
              onPotChanged: (v) {
                _history.push(_state);
                setState(() => _pot = v);
              },
              theme: _theme,
              onThemeChanged: (t) => setState(() => _theme = t),
              boardCards: const [],
              currentStreet: 0,
              showPlayerActions: true,
              sizeFactor: 0.9,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _changeCount(-1),
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$_playerCount',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  onPressed: () => _changeCount(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _resetActions,
              child: const Text('Reset Actions'),
            ),
          ],
        ),
      ),
    );
  }
}
