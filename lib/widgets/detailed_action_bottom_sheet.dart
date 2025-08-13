import 'package:flutter/material.dart';
import '../helpers/poker_street_helper.dart';

Future<Map<String, dynamic>?> showDetailedActionBottomSheet(
  BuildContext context, {
  required int potSizeBB,
  required int stackSizeBB,
  required int currentStreet,
  String? initialAction,
  int? initialAmount,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _DetailedActionSheet(
      potSizeBB: potSizeBB,
      stackSizeBB: stackSizeBB,
      currentStreet: currentStreet,
      initialAction: initialAction,
      initialAmount: initialAmount,
    ),
  );
}

class _DetailedActionSheet extends StatefulWidget {
  final int potSizeBB;
  final int stackSizeBB;
  final int currentStreet;
  final String? initialAction;
  final int? initialAmount;

  const _DetailedActionSheet({
    required this.potSizeBB,
    required this.stackSizeBB,
    required this.currentStreet,
    this.initialAction,
    this.initialAmount,
  });

  @override
  State<_DetailedActionSheet> createState() => _DetailedActionSheetState();
}

class _DetailedActionSheetState extends State<_DetailedActionSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _action;
  double _amount = 1;
  late int _street;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _street = widget.currentStreet;
    if (widget.initialAction != null) {
      _action = widget.initialAction;
      if (widget.initialAmount != null) {
        _amount = widget.initialAmount!.toDouble();
        _controller.text = widget.initialAmount!.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  bool get _needAmount => _action == 'bet' || _action == 'raise';

  void _onActionSelected(String act) {
    if (act == 'bet' || act == 'raise') {
      setState(() {
        _action = act;
      });
    } else {
      Navigator.pop(context, {
        'action': act,
        'amount': null,
        'street': _street,
      });
    }
  }

  void _onSliderChanged(double value) {
    setState(() {
      _amount = value;
      _controller.text = value.round().toString();
    });
  }

  void _onTextChanged() {
    final v = int.tryParse(_controller.text);
    if (v == null) return;
    setState(() {
      _amount = v.clamp(1, widget.stackSizeBB).toDouble();
    });
  }

  void _setQuick(double fraction) {
    final value = (widget.potSizeBB * fraction).round();
    _onSliderChanged(value.clamp(1, widget.stackSizeBB).toDouble());
  }

  Widget _quickSizeButton(String label, double fraction) {
    final bb = widget.potSizeBB * fraction;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => _setQuick(fraction),
          child: Text(label),
        ),
        const SizedBox(height: 2),
        Text(
          '(${bb.toStringAsFixed(1)} BB)',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  void _confirm() {
    if (_action == null) return;
    final result = <String, dynamic>{
      'action': _action,
      'amount': _needAmount ? _amount.round() : null,
      'street': _street,
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    const actions = [
      {'label': 'Fold', 'value': 'fold', 'icon': '❌'},
      {'label': 'Call', 'value': 'call', 'icon': '📞'},
      {'label': 'Check', 'value': 'check', 'icon': '✅'},
      {'label': 'Bet', 'value': 'bet', 'icon': '💰'},
      {'label': 'Raise', 'value': 'raise', 'icon': '📈'},
    ];
    const streetNames = kStreetNames;

    return Padding(
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<int>(
            value: _street,
            dropdownColor: Colors.black87,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white,
            items: [
              for (int i = 0; i < streetNames.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(streetNames[i]),
                ),
            ],
            onChanged: (v) => setState(() => _street = v ?? _street),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < actions.length; i++) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _onActionSelected(actions[i]['value'] as String),
              icon: Text(actions[i]['icon'] as String,
                  style: const TextStyle(fontSize: 24)),
              label: Text(actions[i]['label'] as String,
                  style: const TextStyle(fontSize: 20)),
            ),
            if (i != actions.length - 1) const SizedBox(height: 12),
          ],
          if (_needAmount) ...[
            const SizedBox(height: 20),
            Slider(
              value: _amount,
              min: 1,
              max: widget.stackSizeBB.toDouble(),
              divisions: widget.stackSizeBB - 1,
              label: '${_amount.round()} BB',
              onChanged: _onSliderChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickSizeButton('1/3 pot', 1 / 3),
                _quickSizeButton('1/2 pot', 1 / 2),
                _quickSizeButton('pot', 1),
                _quickSizeButton(
                    'All-in', widget.stackSizeBB / widget.potSizeBB),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                hintText: 'Amount in BB',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_amount.toStringAsFixed(1)} BB',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ],
      ),
    );
  }
}
