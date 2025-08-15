import 'package:flutter/material.dart';
import '../helpers/poker_street_helper.dart';
import 'bet_sizer.dart';

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
  String? _action;
  double _amount = 1;
  late int _street;

  @override
  void initState() {
    super.initState();
    _street = widget.currentStreet;
    if (widget.initialAction != null) {
      _action = widget.initialAction;
      if (widget.initialAmount != null) {
        _amount = widget.initialAmount!.toDouble();
      }
    }
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
            BetSizer(
              min: 1,
              max: widget.stackSizeBB.toDouble(),
              value: _amount,
              bb: 1.0,
              pot: widget.potSizeBB.toDouble(),
              stack: widget.stackSizeBB.toDouble(),
              onChanged: (v) => setState(() => _amount = v),
              onConfirm: _confirm,
            ),
          ],
        ],
      ),
    );
  }
}
