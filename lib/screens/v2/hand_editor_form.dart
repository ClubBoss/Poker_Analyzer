import 'package:flutter/material.dart';

import '../../models/v2/hero_position.dart';
import '../../widgets/action_list_widget.dart';
import 'hand_editor_controller.dart';

/// Visual representation of the hand editor inputs.
class HandEditorForm extends StatelessWidget {
  final HandEditorController controller;
  const HandEditorForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final spot = controller.spot;
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller.cardsCtr,
            decoration: const InputDecoration(labelText: 'Hero cards'),
            onChanged: (_) => controller.update(),
          ),
          const SizedBox(height: 16),
          DropdownButton<HeroPosition>(
            value: controller.position,
            items: [
              for (final p in HeroPosition.values)
                DropdownMenuItem(value: p, child: Text(p.label))
            ],
            onChanged: (v) {
              if (v == null) return;
              controller.position = v;
              controller.update();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Player count'),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: spot.hand.playerCount,
                items: [
                  for (int i = 2; i <= 9; i++)
                    DropdownMenuItem(value: i, child: Text('$i'))
                ],
                onChanged: (v) {
                  if (v == null) return;
                  controller.setPlayerCount(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Stacks (BB)'),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spot.hand.playerCount,
            itemBuilder: (_, i) {
              final ctrl = controller.stackCtr[i];
              return Row(
                children: [
                  SizedBox(width: 32, child: Text('P$i')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'BB',
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                      onChanged: (_) => controller.updateStacks(),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Hero index'),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: spot.hand.heroIndex,
                items: [
                  for (int i = 0; i < spot.hand.playerCount; i++)
                    DropdownMenuItem(value: i, child: Text('$i'))
                ],
                onChanged: (v) {
                  controller.setHeroIndex(v ?? 0);
                },
              ),
              const SizedBox(width: 8),
              const Tooltip(
                message: '0 — SB, 1 — BB, 2 — UTG, 3 — MP, 4 — CO, 5 — BTN',
                child: Icon(Icons.info_outline, size: 16, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButton<int>(
            value: controller.street,
            items: [
              for (int i = 0; i < 4; i++)
                DropdownMenuItem(value: i, child: Text(names[i]))
            ],
            onChanged: (v) => controller.setStreet(v ?? 0),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ActionListWidget(
              playerCount: spot.hand.playerCount,
              heroIndex: spot.hand.heroIndex,
              initial: spot.hand.actions[controller.street],
              onChanged: (list) {
                spot.hand.actions[controller.street] = list;
              },
            ),
          ),
        ],
      ),
    );
  }
}
