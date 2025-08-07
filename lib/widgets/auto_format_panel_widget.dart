import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auto_format_selector.dart';

/// Small dashboard panel showing auto-applied format and controls.
class AutoFormatPanelWidget extends StatefulWidget {
  const AutoFormatPanelWidget({super.key});

  @override
  State<AutoFormatPanelWidget> createState() => _AutoFormatPanelWidgetState();
}

class _AutoFormatPanelWidgetState extends State<AutoFormatPanelWidget> {
  final AutoFormatSelector _selector = AutoFormatSelector();
  bool _autoApply = true;
  String _formatLabel = '-';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _selector.load();
    final fmt = _selector.effectiveFormat();
    setState(() {
      _autoApply = _selector.autoApply;
      _formatLabel =
          '${fmt.spotsPerPack} spots, streets: ${fmt.streets}, theory: ${fmt.theoryRatio.toStringAsFixed(2)}';
    });
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ab.auto_apply', value);
    setState(() {
      _autoApply = value;
    });
  }

  Future<void> _preview() async {
    await _selector.load();
    final fmt = _selector.effectiveFormat();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AutoFormat Preview'),
        content: Text(
            'Spots per pack: ${fmt.spotsPerPack}\nStreets: ${fmt.streets}\nTheory ratio: ${fmt.theoryRatio.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(child: Text('Applied Format: $_formatLabel')),
            Switch(value: _autoApply, onChanged: _toggle),
            TextButton(onPressed: _preview, child: const Text('Preview')),
          ],
        ),
      ),
    );
  }
}
