import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_variant.dart';
import '../../models/v2/hero_position.dart';
import '../../models/game_type.dart';

class NewTrainingPackTemplateDialog extends StatefulWidget {
  const NewTrainingPackTemplateDialog({super.key});

  static Future<TrainingPackTemplate?> show(BuildContext context) {
    return showDialog<TrainingPackTemplate>(
      context: context,
      builder: (_) => const NewTrainingPackTemplateDialog(),
    );
  }

  @override
  State<NewTrainingPackTemplateDialog> createState() =>
      _NewTrainingPackTemplateDialogState();
}

class _NewTrainingPackTemplateDialogState
    extends State<NewTrainingPackTemplateDialog> {
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _rangeCtrl = TextEditingController();
  GameType _type = GameType.tournament;
  String _street = 'any';
  GameType _varType = GameType.tournament;
  HeroPosition _pos = HeroPosition.sb;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _rangeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim().isEmpty ? 'New Pack' : _nameCtrl.text.trim(),
      gameType: _type,
      targetStreet: _street == 'any' ? null : _street,
      streetGoal: int.tryParse(_streetCtrl.text) ?? 0,
      meta: {},
      createdAt: DateTime.now(),
    );
    final range = _rangeCtrl.text.trim();
    template.meta['variants'] = [
      TrainingPackVariant(
        position: _pos,
        gameType: _varType,
        rangeId: range.isEmpty ? null : range,
      ).toJson(),
    ];
    Navigator.pop(context, template);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Pack'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, autofocus: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<GameType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Game Type'),
              items: const [
                DropdownMenuItem(
                  value: GameType.tournament,
                  child: Text('Tournament'),
                ),
                DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
              ],
              onChanged: (v) =>
                  setState(() => _type = v ?? GameType.tournament),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _street,
              decoration: const InputDecoration(labelText: 'Улица целью'),
              items: const [
                DropdownMenuItem(value: 'any', child: Text('Any')),
                DropdownMenuItem(value: 'flop', child: Text('Flop')),
                DropdownMenuItem(value: 'turn', child: Text('Turn')),
                DropdownMenuItem(value: 'river', child: Text('River')),
              ],
              onChanged: (v) => setState(() => _street = v ?? 'any'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _streetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Street Goal (optional)',
                helperText: 'Напр., 50',
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Variant (optional)'),
              children: [
                DropdownButtonFormField<GameType>(
                  value: _varType,
                  decoration: const InputDecoration(labelText: 'Game Type'),
                  items: const [
                    DropdownMenuItem(
                      value: GameType.tournament,
                      child: Text('Tournament'),
                    ),
                    DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
                  ],
                  onChanged: (v) =>
                      setState(() => _varType = v ?? GameType.tournament),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HeroPosition>(
                  value: _pos,
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: const [
                    DropdownMenuItem(value: HeroPosition.sb, child: Text('SB')),
                    DropdownMenuItem(value: HeroPosition.bb, child: Text('BB')),
                    DropdownMenuItem(
                      value: HeroPosition.btn,
                      child: Text('BTN'),
                    ),
                    DropdownMenuItem(value: HeroPosition.co, child: Text('CO')),
                    DropdownMenuItem(value: HeroPosition.mp, child: Text('MP')),
                    DropdownMenuItem(
                      value: HeroPosition.utg,
                      child: Text('UTG'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _pos = v ?? HeroPosition.sb),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _rangeCtrl,
                  decoration: const InputDecoration(labelText: 'ID диапазона'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
