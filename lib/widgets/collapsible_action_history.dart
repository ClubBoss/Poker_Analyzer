import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import '../helpers/action_utils.dart';
import '../services/action_history_service.dart';
import '../utils/responsive.dart';

class CollapsibleActionHistory extends StatefulWidget {
  final ActionHistoryService actionHistory;
  final Map<int, String> playerPositions;
  final int heroIndex;

  const CollapsibleActionHistory({
    super.key,
    required this.actionHistory,
    required this.playerPositions,
    required this.heroIndex,
  });

  @override
  State<CollapsibleActionHistory> createState() => _CollapsibleActionHistoryState();
}

class _CollapsibleActionHistoryState extends State<CollapsibleActionHistory>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late TabController _controller;

  String _iconForAction(String action) {
    switch (action) {
      case 'raise':
        return '🔼';
      case 'call':
        return '📞';
      case 'fold':
        return '❌';
      case 'all-in':
        return '💀';
      case 'custom':
        return '✏️';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ActionEntry> _forStreet(int street) {
    return widget.actionHistory
        .actionsForStreet(street)
        .where((a) => !a.generated)
        .toList();
  }

  Widget _buildList(int street) {
    final list = _forStreet(street);
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No actions', style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final a = list[i];
        final pos =
            widget.playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
        final size = a.amount != null ? ' ${a.amount}' : '';
        final style = TextStyle(
          color: Colors.white,
          fontWeight: a.isHero(widget.heroIndex) ? FontWeight.bold : null,
        );
        return Row(
          children: [
            Text(_iconForAction(a.action), style: style),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                  '$pos ${a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action}$size',
                  style: style),
            ),
          ],
        );
      },
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Colors.white24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            color: Colors.black45,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Action History', style: TextStyle(color: Colors.white)),
                Icon(_open ? Icons.expand_less : Icons.expand_more, color: Colors.white),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            color: Colors.black54,
            height: responsiveSize(context, 200),
            child: Column(
              children: [
                TabBar(
                  controller: _controller,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Preflop'),
                    Tab(text: 'Flop'),
                    Tab(text: 'Turn'),
                    Tab(text: 'River'),
                  ],
                ),
                const Divider(height: 1, color: Colors.white24),
                Expanded(
                  child: TabBarView(
                    controller: _controller,
                    children: [
                      _buildList(0),
                      _buildList(1),
                      _buildList(2),
                      _buildList(3),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
