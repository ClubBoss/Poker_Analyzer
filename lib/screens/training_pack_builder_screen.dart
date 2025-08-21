import 'package:flutter/material.dart';

import '../models/v2/hero_position.dart';
import '../services/training_pack_service.dart';
import '../widgets/range_matrix_picker.dart';

class TrainingPackBuilderScreen extends StatefulWidget {
  const TrainingPackBuilderScreen({super.key});

  @override
  State<TrainingPackBuilderScreen> createState() =>
      _TrainingPackBuilderScreenState();
}

class _TrainingPackBuilderScreenState extends State<TrainingPackBuilderScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _minStackCtrl = TextEditingController(text: '10');
  final TextEditingController _maxStackCtrl = TextEditingController(text: '20');
  final TextEditingController _playersCtrl = TextEditingController(
    text: '10 10',
  );
  Set<String> _range = {};
  HeroPosition _pos = HeroPosition.sb;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minStackCtrl.dispose();
    _maxStackCtrl.dispose();
    _playersCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name =
        _nameCtrl.text.trim().isEmpty ? 'New Pack' : _nameCtrl.text.trim();
    final minBb = int.tryParse(_minStackCtrl.text) ?? 10;
    final maxBb = int.tryParse(_maxStackCtrl.text) ?? minBb;
    final players = [
      for (final s in _playersCtrl.text.split(RegExp(r'[\s,]+')))
        if (s.trim().isNotEmpty) int.tryParse(s) ?? minBb,
    ];
    if (players.isEmpty) players.add(minBb);
    final tpl = await TrainingPackService.createRangePack(
      name: name,
      minBb: minBb,
      maxBb: maxBb,
      playerStacksBb: players,
      heroPos: _pos,
      heroRange: _range.toList(),
    );
    if (!mounted) return;
    Navigator.pop(context, tpl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Pack')),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.check),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<HeroPosition>(
            initialValue: _pos,
            decoration: const InputDecoration(labelText: 'Position'),
            items: [
              for (final p in HeroPosition.values)
                if (p != HeroPosition.unknown)
                  DropdownMenuItem(value: p, child: Text(p.label)),
            ],
            onChanged: (v) => setState(() => _pos = v ?? HeroPosition.sb),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minStackCtrl,
                  decoration: const InputDecoration(labelText: 'Min BB'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxStackCtrl,
                  decoration: const InputDecoration(labelText: 'Max BB'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _playersCtrl,
            decoration: const InputDecoration(labelText: 'Player Stacks'),
          ),
          const SizedBox(height: 12),
          RangeMatrixPicker(
            selected: _range,
            onChanged: (s) => setState(() => _range = s),
          ),
        ],
      ),
    );
  }
}
