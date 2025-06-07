import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/action_entry.dart';

enum PlayerAction { fold, check, call, bet, raise }

class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  final String position;
  final int stackSize;
  final int pot;
  final String? initialAction;
  final int? initialAmount;

  const ActionDialog({
    super.key,
    required this.playerIndex,
    required this.street,
    required this.position,
    required this.stackSize,
    required this.pot,
    this.initialAction,
    this.initialAmount,
  });

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  late PlayerAction _action;
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction != null
        ? PlayerAction.values.firstWhere(
            (a) => describeEnum(a) == widget.initialAction,
            orElse: () => PlayerAction.fold,
          )
        : PlayerAction.fold;
    _controller = TextEditingController(
        text: widget.initialAmount != null ? widget.initialAmount.toString() : '');
  }

  bool get _needsAmount =>
      _action == PlayerAction.bet ||
      _action == PlayerAction.raise ||
      _action == PlayerAction.call;

  int? get _amount {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits);
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ActionEntry(widget.street, widget.playerIndex, describeEnum(_action),
          amount: _needsAmount ? _amount : null),
    );
  }

  int get _callAmount => widget.initialAmount ?? 0;
  int get _halfPot => widget.pot ~/ 2 > widget.stackSize
      ? widget.stackSize
      : widget.pot ~/ 2;
  int get _pot => widget.pot > widget.stackSize ? widget.stackSize : widget.pot;
  int get _allIn => widget.stackSize;

  void _setPreset(int amount) {
    setState(() => _controller.text = amount.toString());
  }

  Widget _buildAmountField(TextStyle textStyle) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      style: textStyle,
      decoration: const InputDecoration(
        labelText: 'Размер',
        labelStyle: TextStyle(color: Colors.white70),
      ),
      validator: (v) {
        if (!_needsAmount) return null;
        final digits = v?.replaceAll(RegExp(r'\D'), '');
        if (digits == null || digits.isEmpty) return 'Введите сумму';
        final value = int.tryParse(digits);
        if (value == null) return 'Неверный формат';
        if (value > widget.stackSize) return 'Недостаточно фишек';
        if (value <= 0) return 'Введите сумму';
        return null;
      },
    );
  }

  void _onActionChanged(PlayerAction? value) {
    if (value == null) return;
    setState(() {
      _action = value;
      switch (_action) {
        case PlayerAction.call:
          _controller.text = _callAmount.toString();
          break;
        case PlayerAction.fold:
        case PlayerAction.check:
          _controller.clear();
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(color: Colors.white);
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(
        'Игрок ${widget.playerIndex + 1} (${widget.position})',
        style: textStyle,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<PlayerAction>(
              value: _action,
              dropdownColor: Colors.black87,
              decoration: const InputDecoration(
                labelText: 'Действие',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: [
                for (final a in PlayerAction.values)
                  DropdownMenuItem(
                    value: a,
                    child: Text(describeEnum(a), style: textStyle),
                  )
              ],
              onChanged: _onActionChanged,
            ),
            if (_needsAmount)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildAmountField(textStyle),
              ),
            if (_needsAmount)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () => _setPreset(_halfPot),
                        child: const Text('1/2 pot')),
                    TextButton(
                        onPressed: () => _setPreset(_pot),
                        child: const Text('pot')),
                    TextButton(
                        onPressed: () => _setPreset(_allIn),
                        child: const Text('all-in')),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
