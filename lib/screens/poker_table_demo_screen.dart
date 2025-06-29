import 'package:flutter/material.dart';
import '../widgets/poker_table_view.dart';

class PokerTableDemoScreen extends StatefulWidget {
  const PokerTableDemoScreen({super.key});

  @override
  State<PokerTableDemoScreen> createState() => _PokerTableDemoScreenState();
}

class _PokerTableDemoScreenState extends State<PokerTableDemoScreen> {
  int _playerCount = 6;
  late List<String> _names;
  late List<double> _stacks;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _names = List.generate(_playerCount, (i) => 'Player ${i + 1}');
    _stacks = List.filled(_playerCount, 0.0);
    _heroIndex = 0;
  }

  void _changeCount(int delta) {
    setState(() {
      _playerCount = (_playerCount + delta).clamp(2, 10);
      if (_names.length < _playerCount) {
        final start = _names.length;
        _names.addAll(
            List.generate(_playerCount - start, (i) => 'Player ${start + i + 1}'));
      } else if (_names.length > _playerCount) {
        _names = _names.sublist(0, _playerCount);
      }
      if (_stacks.length < _playerCount) {
        _stacks.addAll(List.filled(_playerCount - _stacks.length, 0.0));
      } else if (_stacks.length > _playerCount) {
        _stacks = _stacks.sublist(0, _playerCount);
      }
      if (_heroIndex >= _playerCount) _heroIndex = _playerCount - 1;
    });
  }

  void _clear() => setState(_reset);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Table Demo'),
        actions: [IconButton(icon: const Icon(Icons.clear), onPressed: _clear)],
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
              onHeroSelected: (i) => setState(() => _heroIndex = i),
              onStackChanged: (i, v) => setState(() => _stacks[i] = v),
              onNameChanged: (i, v) => setState(() => _names[i] = v),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _changeCount(-1),
                  icon: const Icon(Icons.remove),
                ),
                Text('$_playerCount', style: const TextStyle(color: Colors.white)),
                IconButton(
                  onPressed: () => _changeCount(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
