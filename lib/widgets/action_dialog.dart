import 'package:flutter/material.dart';
import '../models/action_entry.dart';

/// Диалог ввода действия игрока
Future<ActionEntry?> showActionDialog(
  BuildContext context, {
  required int street,
  required int playerIndex,
  required int callAmount,
  required bool hasBet,
}) {
  return showGeneralDialog<ActionEntry>(
    context: context,
    barrierLabel: 'action',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim1, anim2) {
      return _ActionDialogContent(
        street: street,
        playerIndex: playerIndex,
        callAmount: callAmount,
        hasBet: hasBet,
      );
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return SlideTransition(
        position:
            Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

class _ActionDialogContent extends StatefulWidget {
  final int street;
  final int playerIndex;
  final int callAmount;
  final bool hasBet;

  const _ActionDialogContent({
    Key? key,
    required this.street,
    required this.playerIndex,
    required this.callAmount,
    required this.hasBet,
  }) : super(key: key);

  @override
  State<_ActionDialogContent> createState() => _ActionDialogContentState();
}

class _ActionDialogContentState extends State<_ActionDialogContent> {
  final TextEditingController _amountController = TextEditingController();
  bool _showAmountField = false;
  bool _useBB = false;

  static const int _chipsPerBB = 20;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit(String action) {
    int? amount;
    if (action == 'call') {
      amount = widget.callAmount;
    } else if (action == 'bet' || action == 'raise') {
      final input = int.tryParse(_amountController.text);
      if (input == null) {
        setState(() => _showAmountField = true);
        return;
      }
      amount = _useBB ? input * _chipsPerBB : input;
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.of(context).pop(
        ActionEntry(widget.street, widget.playerIndex, action, amount),
      );
    });
  }

  Widget _buildButton(String action, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: () {
          if (action == 'bet' || action == 'raise') {
            if (!_showAmountField) {
              setState(() => _showAmountField = true);
              return;
            }
          }
          _submit(action);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildButton('fold', 'Fold', Colors.red),
              _buildButton(
                widget.callAmount > 0 ? 'call' : 'check',
                widget.callAmount > 0
                    ? 'Call (${widget.callAmount})'
                    : 'Check',
                Colors.blue,
              ),
              _buildButton(
                widget.hasBet ? 'raise' : 'bet',
                widget.hasBet ? 'Raise' : 'Bet',
                Colors.green,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showAmountField
                    ? Padding(
                        key: const ValueKey('amount-field'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ToggleButtons(
                              isSelected: [!_useBB, _useBB],
                              onPressed: (index) {
                                setState(() => _useBB = index == 1);
                              },
                              color: Colors.white70,
                              selectedColor: Colors.white,
                              fillColor: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8),
                              constraints: const BoxConstraints(minHeight: 36),
                              children: const [
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Фишки'),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('BB'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText:
                                    _useBB ? 'Сумма в BB' : 'Сумма в фишках',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) =>
                                  _submit(widget.hasBet ? 'raise' : 'bet'),
                            ),
                            if (_useBB && _amountController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '≈ ${(int.tryParse(_amountController.text) ?? 0) * _chipsPerBB} фишек',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
