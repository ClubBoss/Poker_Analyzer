import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/hero_position.dart';
import '../../models/action_entry.dart';
import '../../screens/v2/hand_editor_screen.dart';

class TrainingPackSpotPreviewCard extends StatelessWidget {
  final TrainingPackSpot spot;
  final VoidCallback? onHandEdited;
  final ValueChanged<String>? onTagTap;
  final VoidCallback? onDuplicate;
  final Color? titleColor;
  const TrainingPackSpotPreviewCard({
    super.key,
    required this.spot,
    this.onHandEdited,
    this.onTagTap,
    this.onDuplicate,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final hero = spot.hand.heroCards;
    final pos = spot.hand.position;
    final h = spot.hand.heroIndex;
    final pre = spot.hand.actions[0] ?? [];

    ActionEntry? heroAct;
    for (final a in pre) {
      if (a.playerIndex == h) {
        heroAct = a;
        break;
      }
    }
    final double? heroEv = heroAct?.ev;
    final double? heroIcmEv = heroAct?.icmEv;
    final borderColor = heroEv == null
        ? Colors.grey
        : (heroEv.abs() <= 0.01
            ? Colors.grey
            : (heroEv > 0 ? Colors.green : Colors.red));
    final badgeColor = borderColor;
    final badgeText = heroEv == null
        ? ''
        : '${heroEv > 0 ? '+' : ''}${heroEv.toStringAsFixed(1)}';
    final icmBadgeText = heroIcmEv == null
        ? ''
        : '${heroIcmEv > 0 ? '+' : ''}${heroIcmEv.toStringAsFixed(3)}';

    final String? heroLabel = heroAct == null
        ? null
        : (heroAct.customLabel?.isNotEmpty == true
            ? heroAct.customLabel!
            : '${heroAct.action}${heroAct.amount != null && heroAct.amount! > 0 ? ' ${heroAct.amount!.toStringAsFixed(1)} BB' : ''}');
    final legacy = hero.isEmpty && spot.note.trim().isNotEmpty;
    final actions = spot.hand.actions;
    final board = [
      for (final street in [1, 2, 3])
        for (final a in actions[street] ?? [])
          if (a.action == 'board' && a.customLabel?.isNotEmpty == true)
            ...a.customLabel!.split(' ')
    ];
    final actionCount = actions.values
        .expand((e) => e)
        .where((a) => a.action != 'board' && !a.generated)
        .length;
    final ev = spot.evalResult?.ev;
    Color? barColor;
    if (ev != null) {
      if (ev >= 0.5) {
        barColor = Colors.green;
      } else if (ev <= -0.5) {
        barColor = Colors.red;
      } else {
        barColor = Colors.yellow;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (barColor != null)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spot.title.isEmpty ? 'Untitled spot' : spot.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (spot.hand.playerCount > 2)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${spot.hand.playerCount}-handed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (heroEv != null) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              key: const ValueKey('evBadge'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (heroIcmEv != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                key: const ValueKey('icmBadge'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  icmBadgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (hero.isNotEmpty || pos != HeroPosition.unknown || legacy)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        legacy ? '(legacy)' : '$hero ${pos.label}'.trim(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  if (heroLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        heroLabel.length > 40
                            ? heroLabel.substring(0, 40)
                            : heroLabel,
                        style: const TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (board.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [for (final c in board) Text(c)],
                      ),
                    ),
                  if (heroEv != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        heroEv >= 0
                            ? '+${heroEv.toStringAsFixed(2)} BB EV'
                            : '${heroEv.toStringAsFixed(2)} BB EV',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: heroEv >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                  if (spot.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final tag in spot.tags)
                            InputChip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () =>
                                  onTagTap?.call(tag.toLowerCase()),
                            ),
                        ],
                      ),
                    ),
                  if (actionCount > 0 || spot.note.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('🕹️ $actionCount',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                          if (spot.note.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('📝',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ]
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HandEditorScreen(spot: spot)),
                          );
                          onHandEdited?.call();
                        },
                        child: const Text('✏️ Edit Hand'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDuplicate,
                        child: const Text('📄 Duplicate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (spot.pinned)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '📌 Pinned',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
