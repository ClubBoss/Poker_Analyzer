import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class ActionDialog extends StatefulWidget {
  final int playerIndex;
  final int street;
  final int pot;
  final int stackSize;
  const ActionDialog({
    Key? key,
    required this.playerIndex,
    required this.street,
    required this.pot,
    required this.stackSize,
  }) : super(key: key);

  @override
  _ActionDialogState createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  String selectedAction = 'Check';
  final TextEditingController _amountController = TextEditingController();
  bool _useBB = true;
  double _sliderValue = 1;

  @override
  void initState() {
    super.initState();
    _amountController.text = _sliderValue.round().toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setValueFromChips(int chips) {
    final value = _useBB ? chips / 20 : chips.toDouble();
    setState(() {
      _sliderValue = value.clamp(1, 100).toDouble();
      _amountController.text = _sliderValue.round().toString();
    });
  }

  int _currentAmountInChips() {
    final val = int.tryParse(_amountController.text) ?? 0;
    return _useBB ? val * 20 : val;
  }

  void _toggleUnit(bool useBB) {
    if (_useBB == useBB) return;
    final chips = _currentAmountInChips();
    setState(() {
      _useBB = useBB;
      _sliderValue = (_useBB ? chips / 20 : chips.toDouble()).clamp(1, 100).toDouble();
      _amountController.text = _sliderValue.round().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Выберите действие для игрока ${widget.playerIndex + 1}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: selectedAction,
            items: ['Fold', 'Check', 'Call', 'Bet', 'Raise']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedAction = value);
              }
            },
          ),
          if (selectedAction == 'Bet' || selectedAction == 'Raise') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _setValueFromChips((widget.pot / 2).round()),
                  child: const Text('1/2 пота'),
                ),
                ElevatedButton(
                  onPressed: () => _setValueFromChips(widget.pot),
                  child: const Text('Пот'),
                ),
                ElevatedButton(
                  onPressed: () => _setValueFromChips(widget.stackSize),
                  child: const Text('Олл-ин'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [_useBB, !_useBB],
              onPressed: (i) => _toggleUnit(i == 0),
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('BB'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Фишки'),
                ),
              ],
            ),
            Slider(
              value: _sliderValue,
              min: 1,
              max: 100,
              divisions: 99,
              label: _sliderValue.round().toString(),
              onChanged: (val) {
                setState(() {
                  _sliderValue = val;
                  _amountController.text = val.round().toString();
                });
              },
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: _useBB ? 'Сумма в BB' : 'Сумма в фишках',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final v = int.tryParse(val);
                if (v != null) {
                  setState(() => _sliderValue = v.clamp(1, 100).toDouble());
                }
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            int? amount;
            if (selectedAction == 'Bet' || selectedAction == 'Raise') {
              amount = _currentAmountInChips();
            }
            Navigator.pop(
              context,
              ActionEntry(
                widget.street,
                widget.playerIndex,
                selectedAction.toLowerCase(),
                amount,
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
