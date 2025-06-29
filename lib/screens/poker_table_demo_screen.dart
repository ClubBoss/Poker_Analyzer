import 'package:flutter/material.dart';
import '../widgets/poker_table_view.dart';

class PokerTableDemoScreen extends StatefulWidget {
  const PokerTableDemoScreen({super.key});

  @override
  State<PokerTableDemoScreen> createState() => _PokerTableDemoScreenState();
}

class _PokerTableDemoScreenState extends State<PokerTableDemoScreen> {
  static const _playerCount = 6;
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

  void _clear() => setState(_reset);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Table Demo'),
        actions: [IconButton(icon: const Icon(Icons.clear), onPressed: _clear)],
      ),
      body: Center(
        child: PokerTableView(
          heroIndex: _heroIndex,
          playerCount: _playerCount,
          playerNames: _names,
          playerStacks: _stacks,
          onHeroSelected: (i) => setState(() => _heroIndex = i),
          onStackChanged: (i, v) => setState(() => _stacks[i] = v),
          onNameChanged: (i, v) => setState(() => _names[i] = v),
        ),
      ),
    );
  }
}
