import 'package:flutter/material.dart';
import '../models/action_entry.dart';
import 'dart:math' as math;

class ActionListWidget extends StatefulWidget {
  final int playerCount;
  final int heroIndex;
  final ValueChanged<List<ActionEntry>> onChanged;
  final List<ActionEntry>? initial;
  final bool showPot;
  final List<double>? currentStacks;
  const ActionListWidget({
    super.key,
    required this.playerCount,
    required this.heroIndex,
    required this.onChanged,
    this.initial,
    this.showPot = false,
    this.currentStacks,
  });

  @override
  State<ActionListWidget> createState() => _ActionListWidgetState();
}

class _ActionListWidgetState extends State<ActionListWidget> {
  late List<ActionEntry> _actions;
  List<String?> _errors = [];
  final ScrollController _scroll = ScrollController();
  List<double> _potsBefore = [];
  List<double> _prevBets = [];

  double? _breakevenEquity({
    required double prevBet,
    required double pot,
    required String amountStr,
  }) {
    final amount = double.tryParse(amountStr) ?? 0;
    final toCall = math.max(0, amount - prevBet);
    final potAfter = pot + toCall;
    return potAfter > 0 ? 100 * toCall / potAfter : null;
  }

  void _recalcErrors() {
    final bets = List<double>.filled(widget.playerCount, 0);
    _errors = List<String?>.filled(_actions.length, null);
    _potsBefore = List<double>.filled(_actions.length, 0);
    _prevBets = List<double>.filled(_actions.length, 0);
    for (int i = 0; i < _actions.length; i++) {
      final a = _actions[i];
      _potsBefore[i] = i == 0 ? 0 : _actions[i - 1].potAfter;
      _prevBets[i] = bets[a.playerIndex];
      if (a.action == 'custom') {
        _errors[i] = null;
        continue;
      }
      String? err;
      if (a.action != 'post') {
        final amount = a.amount;
        if (amount != null && amount < 0) {
          err = 'amount < 0';
        } else if ((a.action == 'call' ||
                a.action == 'raise' ||
                a.action == 'push') &&
            amount == null) {
          err = 'нет размера';
        } else {
          final maxBet = bets.fold<double>(0, math.max);
          if (a.action == 'raise' && amount != null && amount <= maxBet) {
            err = 'raise ≤ текущего бет-сайза';
          } else if (a.action == 'call' && amount != null && amount < maxBet) {
            err = 'call < текущего бет-сайза';
          } else if (a.action == 'push') {
            final stack = widget.currentStacks?[a.playerIndex];
            if (stack != null && amount != stack) {
              err = 'push ≠ стеку';
            }
          }
        }
      }
      _errors[i] = err;
      switch (a.action) {
        case 'post':
        case 'call':
        case 'raise':
        case 'push':
          bets[a.playerIndex] = a.amount ?? bets[a.playerIndex];
          break;
        default:
          break;
      }
    }
  }

  String _format(ActionEntry a) {
    final label = a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
    var text = 'P${a.playerIndex} $label';
    if (a.amount != null) text += ' ${a.amount}';
    return text;
  }

  @override
  void initState() {
    super.initState();
    _actions = List<ActionEntry>.from(widget.initial ?? []);
    if (_actions.isEmpty) {
      _actions
        ..add(ActionEntry(0, 0, 'post', amount: 0.5))
        ..add(ActionEntry(0, 1, 'post', amount: 1.0));
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onChanged(List<ActionEntry>.from(_actions)),
      );
    }
    _recalcErrors();
  }

  @override
  void didUpdateWidget(covariant ActionListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStacks != widget.currentStacks) {
      setState(() => _recalcErrors());
    }
  }

  void _notify() {
    setState(() => _recalcErrors());
    widget.onChanged(List<ActionEntry>.from(_actions));
  }

  Future<ActionEntry?> _showDialog(ActionEntry entry) {
    int player = entry.playerIndex;
    String act = entry.action;
    final amountController = TextEditingController(
      text: entry.amount?.toString() ?? '',
    );
    final labelController = TextEditingController(
      text: entry.customLabel ?? '',
    );
    final equityController = TextEditingController(
      text: entry.equity?.toString() ?? '',
    );
    final pa = entry.potAfter;
    final po = entry.potOdds;
    final origAmount = entry.amount ?? 0;
    final baseToCall = po == null ? 0 : pa * po / 100;
    final currentPot = pa - baseToCall;
    final prevBet = origAmount - baseToCall;
    return showDialog<ActionEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final needAmount = act != 'fold' && act != 'custom';
          final needLabel = act == 'custom';
          final needEquity =
              player == widget.heroIndex && (act == 'call' || act == 'push');

          return AlertDialog(
            title: const Text('Edit action'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: player,
                  items: [
                    for (int p = 0; p < widget.playerCount; p++)
                      DropdownMenuItem(value: p, child: Text('$p')),
                  ],
                  onChanged: (v) => setState(() => player = v ?? player),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: act,
                  items: const [
                    DropdownMenuItem(value: 'fold', child: Text('fold')),
                    DropdownMenuItem(value: 'call', child: Text('call')),
                    DropdownMenuItem(value: 'raise', child: Text('raise')),
                    DropdownMenuItem(value: 'push', child: Text('push')),
                    DropdownMenuItem(value: 'custom', child: Text('custom')),
                  ],
                  onChanged: (v) => setState(() => act = v ?? act),
                ),
                if (needAmount) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  if (['post', 'call', 'raise', 'push'].contains(act)) ...[
                    ValueListenableBuilder(
                      valueListenable: amountController,
                      builder: (_, __, ___) {
                        final amt = double.tryParse(amountController.text);
                        if (amt == null || amt < 0) {
                          return const SizedBox.shrink();
                        }
                        final diff = math.max(0, amt - prevBet);
                        final potAfterLive = currentPot + diff;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Pot after action: ${potAfterLive.toStringAsFixed(1)} BB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: amountController,
                      builder: (_, __, ___) {
                        if (currentPot <= 0) return const SizedBox.shrink();
                        final amt = double.tryParse(amountController.text);
                        if (amt == null || amt < 0) {
                          return const SizedBox.shrink();
                        }
                        final diff = math.max(0, amt - prevBet);
                        final pct = 100 * diff / currentPot;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Size: ${pct.toStringAsFixed(0)} % pot',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
                if (needEquity) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: equityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Equity %'),
                  ),
                  ValueListenableBuilder(
                    valueListenable: amountController,
                    builder: (_, __, ___) {
                      final t = _breakevenEquity(
                        prevBet: prevBet,
                        pot: currentPot,
                        amountStr: amountController.text,
                      );
                      return t != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Tooltip(
                                message: 'Break-even equity for this call/push',
                                child: Text(
                                  'EV=0 at ~${t.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
                if (needLabel) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    ctx,
                    ActionEntry(
                      entry.street,
                      player,
                      act,
                      amount: needAmount
                          ? double.tryParse(amountController.text)
                          : null,
                      customLabel: needLabel ? labelController.text : null,
                      equity: needEquity
                          ? double.tryParse(equityController.text)
                          : null,
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addAction() async {
    final entry = await _showDialog(ActionEntry(0, 0, 'custom'));
    if (entry != null) {
      setState(() {
        _actions.add(entry);
        _recalcErrors();
      });
      _notify();
      await Future.delayed(const Duration(milliseconds: 50));
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _editAction(int index) async {
    final edited = await _showDialog(_actions[index]);
    if (edited != null) {
      setState(() {
        _actions[index] = edited;
        _recalcErrors();
      });
      _notify();
    }
  }

  void _deleteAction(int index) {
    setState(() {
      _actions.removeAt(index);
      _recalcErrors();
    });
    _notify();
  }

  Future<void> _duplicateAction(int index) async {
    final a = _actions[index];
    setState(() {
      final clone = ActionEntry(
        a.street,
        a.playerIndex,
        a.action,
        amount: a.amount,
        customLabel: a.customLabel,
        equity: a.equity,
        potAfter: 0,
      );
      _actions.insert(index + 1, clone);
      _recalcErrors();
    });
    _notify();
    await Future.delayed(const Duration(milliseconds: 50));
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _clearAllActions() {
    setState(() {
      _actions.clear();
      _recalcErrors();
    });
    _notify();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All actions cleared')));
  }

  @override
  Widget build(BuildContext context) {
    if (_actions.isEmpty) {
      return TextButton(
        onPressed: _addAction,
        child: const Text('＋ Add action'),
      );
    }

    return Column(
      children: [
        ReorderableListView.builder(
          controller: _scroll,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _actions.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final moved = _actions.removeAt(oldIndex);
              _actions.insert(
                newIndex > oldIndex ? newIndex - 1 : newIndex,
                moved,
              );
              _recalcErrors();
            });
            _notify();
          },
          itemBuilder: (context, index) {
            final a = _actions[index];
            final isBlind = index < 2 && a.action == 'post';
            final heroBg = (a.playerIndex == widget.heroIndex && a.ev != null)
                ? (a.ev! >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1))
                : null;
            final bg = heroBg ??
                (_errors[index] == null
                    ? Colors.transparent
                    : Colors.red.withValues(alpha: 0.15));
            return Container(
              key: ValueKey(a),
              color: bg,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (isBlind)
                    const SizedBox(width: 24)
                  else
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_indicator,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_format(a)),
                            if ([
                                  'post',
                                  'call',
                                  'raise',
                                  'push',
                                ].contains(a.action) &&
                                a.amount != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Builder(
                                  builder: (_) {
                                    final pb = _potsBefore[index];
                                    if (pb <= 0) return const SizedBox();
                                    final toCall = math.max(
                                      0,
                                      a.amount! - _prevBets[index],
                                    );
                                    final pct = 100 * toCall / pb;
                                    return Text(
                                      '(${pct.toStringAsFixed(0)} % pot)',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (a.playerIndex == widget.heroIndex &&
                                a.ev != null &&
                                a.action != 'custom')
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: a.ev! >= 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  a.ev! >= 0 ? ' +EV ' : ' -EV ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (a.potOdds != null && a.action != 'custom')
                          Text(
                            'Pot odds: ${a.potOdds!.toStringAsFixed(1)} %',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.showPot && a.action != 'custom')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Pot: ${a.potAfter.toStringAsFixed(1)} BB',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (_errors[index] != null)
                    Tooltip(
                      message: _errors[index]!,
                      child: const Icon(Icons.error, color: Colors.redAccent),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => _editAction(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAction(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    tooltip: 'Duplicate action',
                    onPressed: () => _duplicateAction(index),
                  ),
                ],
              ),
            );
          },
        ),
        if (_actions.isNotEmpty)
          Builder(
            builder: (context) {
              ActionEntry? pot;
              for (final a in _actions.reversed) {
                if (a.potAfter > 0) {
                  pot = a;
                  break;
                }
              }
              return pot != null
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Text(
                          'Total pot: ${pot.potAfter.toStringAsFixed(1)} BB',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        Row(
          children: [
            TextButton(
              onPressed: _addAction,
              child: const Text('＋ Add action'),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllActions,
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}
