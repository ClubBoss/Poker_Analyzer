import 'package:flutter/material.dart';

import '../models/action_entry.dart';
import '../helpers/poker_street_helper.dart';
import 'street_actions_list.dart';
import 'package:sticky_headers/sticky_headers.dart';

class ActionHistoryExpansionTile extends StatefulWidget {
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final List<int> pots;
  final Map<int, int> stackSizes;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;
  final void Function(int) onDuplicate;
  final void Function(int, int)? onReorder;
  final int visibleCount;
  final String Function(ActionEntry)? evaluateActionQuality;
  final void Function(int index, ActionEntry entry)? onInsert;

  const ActionHistoryExpansionTile({
    super.key,
    required this.actions,
    required this.playerPositions,
    required this.pots,
    required this.stackSizes,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    this.onReorder,
    this.onInsert,
    required this.visibleCount,
    this.evaluateActionQuality,
  });

  @override
  State<ActionHistoryExpansionTile> createState() =>
      _ActionHistoryExpansionTileState();
}

class _ActionHistoryExpansionTileState
    extends State<ActionHistoryExpansionTile> {
  bool _expanded = false;
  late List<bool> _streetExpanded;

  @override
  void initState() {
    super.initState();
    _streetExpanded = List<bool>.filled(kStreetNames.length, true);
  }

  void _toggleAll() {
    final shouldExpand = _streetExpanded.any((e) => !e);
    setState(() {
      for (var i = 0; i < _streetExpanded.length; i++) {
        _streetExpanded[i] = shouldExpand;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        title: const Text(
          'Show Action History',
          style: TextStyle(color: Colors.white),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _streetExpanded.every((e) => e)
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Colors.white,
              ),
              onPressed: _toggleAll,
            ),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more, color: Colors.white),
            ),
          ],
        ),
        textColor: Colors.white,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        collapsedTextColor: Colors.white,
        collapsedBackgroundColor: Colors.black45,
        backgroundColor: Colors.black54,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (int i = 0; i < kStreetNames.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: StickyHeader(
                header: GestureDetector(
                  onTap: () =>
                      setState(() => _streetExpanded[i] = !_streetExpanded[i]),
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          streetName(i),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _streetExpanded[i]
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                content: ClipRect(
                  child: AnimatedAlign(
                    alignment: Alignment.topCenter,
                    duration: const Duration(milliseconds: 300),
                    heightFactor: _streetExpanded[i] ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: StreetActionsList(
                        street: i,
                        actions: widget.actions,
                        pots: widget.pots,
                        stackSizes: widget.stackSizes,
                        playerPositions: widget.playerPositions,
                        numberOfPlayers: widget.playerPositions.length,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                        onInsert: widget.onInsert,
                        onDuplicate: widget.onDuplicate,
                        onReorder: widget.onReorder,
                        visibleCount: widget.visibleCount,
                        evaluateActionQuality: widget.evaluateActionQuality,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

