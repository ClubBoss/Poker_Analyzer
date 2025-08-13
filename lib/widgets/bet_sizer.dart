import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BetSizer extends StatefulWidget {
  final int pot;
  final int stackSize;
  final ValueChanged<int> onSelected;
  final int? initialAmount;

  const BetSizer({
    Key? key,
    required this.pot,
    required this.stackSize,
    required this.onSelected,
    this.initialAmount,
  }) : super(key: key);

  @override
  State<BetSizer> createState() => _BetSizerState();
}

String _formatWithSpaces(String digits) {
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = _formatWithSpaces(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _BetSizerState extends State<BetSizer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    if (widget.initialAmount != null) {
      final formatted = _formatWithSpaces(widget.initialAmount!.toString());
      _controller.text = formatted;
    }
  }

  int? get _currentAmount {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    final int? value = int.tryParse(digits);
    if (value == null || value <= 0) return null;
    return value.clamp(1, widget.stackSize);
  }

  void _setAmount(int amount) {
    final clamped = amount.clamp(1, widget.stackSize);
    final formatted = _formatWithSpaces(clamped.toString());
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Widget _quickButton(String label, double fraction) {
    final int amount = (widget.pot * fraction).round();
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
      ),
      onPressed: () => _setAmount(amount),
      child: Text(label),
    );
  }

  void _submit() {
    final int? amount = _currentAmount;
    if (amount != null) {
      widget.onSelected(amount);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool valid = _currentAmount != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickButton('½ Pot', 0.5),
            _quickButton('⅔ Pot', 2 / 3),
            _quickButton('Pot', 1.0),
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsFormatter(),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Введите ставку',
              hintStyle: const TextStyle(color: Colors.white70),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: valid ? 1.0 : 0.6,
          child: ElevatedButton(
            onPressed: valid ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('OK'),
          ),
        ),
      ],
    );
  }
}
