import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BetSizer extends StatefulWidget {
  final int pot;
  final int stackSize;
  final ValueChanged<int> onSelected;

  const BetSizer({
    Key? key,
    required this.pot,
    required this.stackSize,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<BetSizer> createState() => _BetSizerState();
}

class _BetSizerState extends State<BetSizer> {
  double _value = 0;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Widget _quickButton(String label, double fraction) {
    final int amount = (widget.pot * fraction).round().clamp(0, widget.stackSize);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
      onPressed: () => widget.onSelected(amount),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  void _handleEnd(double val) {
    if (val > 0) {
      widget.onSelected(val.round());
      setState(() => _value = 0);
    }
  }

  void _submitManual() {
    final int? input = int.tryParse(_controller.text);
    if (input == null || input <= 0) return;
    final int amount = input.clamp(1, widget.stackSize);
    widget.onSelected(amount);
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickButton('33% Pot', 0.33),
            _quickButton('50% Pot', 0.5),
            _quickButton('75% Pot', 0.75),
            _quickButton('100% Pot', 1.0),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Введите ставку',
              hintStyle: const TextStyle(color: Colors.white70),
            ),
            onSubmitted: (_) => _submitManual(),
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _value,
          min: 0,
          max: widget.stackSize.toDouble(),
          divisions: widget.stackSize > 0 ? widget.stackSize : 1,
          label: _value.round().toString(),
          onChanged: (v) => setState(() => _value = v),
          onChangeEnd: _handleEnd,
        ),
        const SizedBox(height: 8),
        Text(
          _value.round().toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
