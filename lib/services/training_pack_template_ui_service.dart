import 'package:flutter/material.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/action_entry.dart';
import '../helpers/hand_utils.dart';
import 'pack_generator_service.dart';
import 'push_fold_ev_service.dart';
import '../utils/template_coverage_utils.dart';

class TrainingPackTemplateUiService {
  TrainingPackTemplateUiService();

  Future<List<TrainingPackSpot>> generateSpotsWithProgress(
    BuildContext context,
    TrainingPackTemplate template,
  ) async {
    final range =
        template.heroRange ?? PackGeneratorService.topNHands(25).toList();
    final total = template.spotCount;
    final generated = <TrainingPackSpot>[];
    var cancel = false;
    var done = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final isHu = template.playerStacksBb.length == 2;
                const idxBB = 1;
                final callCutoff =
                    (PackGeneratorService.handRanking.length *
                            template.bbCallPct /
                            100)
                        .round();
                for (
                  var i = 0;
                  i < range.length && generated.length < total;
                  i++
                ) {
                  if (cancel) break;
                  final hand = range[i];
                  final heroCards = _firstCombo(hand);
                  final actions = {
                    0: [
                      ActionEntry(
                        0,
                        0,
                        'push',
                        amount: template.heroBbStack.toDouble(),
                      ),
                      for (var j = 1; j < template.playerStacksBb.length; j++)
                        if (isHu &&
                            j == idxBB &&
                            PackGeneratorService.handRanking.indexOf(hand) <
                                callCutoff)
                          ActionEntry(
                            0,
                            j,
                            'call',
                            amount: template.heroBbStack.toDouble(),
                          )
                        else
                          ActionEntry(0, j, 'fold'),
                    ],
                  };
                  final ev = computePushEV(
                    heroBbStack: template.heroBbStack,
                    bbCount: template.playerStacksBb.length - 1,
                    heroHand: hand,
                    anteBb: template.anteBb,
                  );
                  final icm = computeIcmPushEV(
                    chipStacksBb: template.playerStacksBb,
                    heroIndex: 0,
                    heroHand: hand,
                    chipPushEv: ev,
                  );
                  actions[0]![0] = actions[0]![0].copyWith(ev: ev, icmEv: icm);
                  final stacks = {
                    for (var j = 0; j < template.playerStacksBb.length; j++)
                      '$j': template.playerStacksBb[j].toDouble(),
                  };
                  generated.add(
                    TrainingPackSpot(
                      id: '${template.id}_${template.spots.length + generated.length + 1}',
                      title: '$hand push',
                      hand: HandData(
                        heroCards: heroCards,
                        position: template.heroPos,
                        heroIndex: 0,
                        playerCount: template.playerStacksBb.length,
                        stacks: stacks,
                        actions: actions,
                        anteBb: template.anteBb,
                      ),
                      tags: const ['pushfold'],
                    ),
                  );
                  done = generated.length;
                  setState(() {});
                  await Future.delayed(Duration.zero);
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generating $done of $total spots...'),
              actions: [
                TextButton(
                  onPressed: () => cancel = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    TemplateCoverageUtils.recountAll(template).applyTo(template.meta);
    template.lastGeneratedAt = DateTime.now();
    return generated;
  }

  Future<List<TrainingPackSpot>> generateMissingSpotsWithProgress(
    BuildContext context,
    TrainingPackTemplate template,
  ) async {
    final existing = <String>{
      for (final s in template.spots)
        if (handCode(s.hand.heroCards) != null) handCode(s.hand.heroCards)!,
    };
    if (existing.length >= template.spotCount) return [];
    final range =
        (template.heroRange ?? PackGeneratorService.topNHands(25).toList())
            .where((h) => !existing.contains(h))
            .toList();
    final total = template.spotCount - existing.length;
    final generated = <TrainingPackSpot>[];
    var cancel = false;
    var done = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                final isHu = template.playerStacksBb.length == 2;
                const idxBB = 1;
                final callCutoff =
                    (PackGeneratorService.handRanking.length *
                            template.bbCallPct /
                            100)
                        .round();
                for (
                  var i = 0;
                  i < range.length && generated.length < total;
                  i++
                ) {
                  if (cancel) break;
                  final hand = range[i];
                  final heroCards = _firstCombo(hand);
                  final actions = {
                    0: [
                      ActionEntry(
                        0,
                        0,
                        'push',
                        amount: template.heroBbStack.toDouble(),
                      ),
                      for (var j = 1; j < template.playerStacksBb.length; j++)
                        if (isHu &&
                            j == idxBB &&
                            PackGeneratorService.handRanking.indexOf(hand) <
                                callCutoff)
                          ActionEntry(
                            0,
                            j,
                            'call',
                            amount: template.heroBbStack.toDouble(),
                          )
                        else
                          ActionEntry(0, j, 'fold'),
                    ],
                  };
                  final ev = computePushEV(
                    heroBbStack: template.heroBbStack,
                    bbCount: template.playerStacksBb.length - 1,
                    heroHand: hand,
                    anteBb: template.anteBb,
                  );
                  final icm = computeIcmPushEV(
                    chipStacksBb: template.playerStacksBb,
                    heroIndex: 0,
                    heroHand: hand,
                    chipPushEv: ev,
                  );
                  actions[0]![0] = actions[0]![0].copyWith(ev: ev, icmEv: icm);
                  final stacks = {
                    for (var j = 0; j < template.playerStacksBb.length; j++)
                      '$j': template.playerStacksBb[j].toDouble(),
                  };
                  generated.add(
                    TrainingPackSpot(
                      id: '${template.id}_${template.spots.length + generated.length + 1}',
                      title: '$hand push',
                      hand: HandData(
                        heroCards: heroCards,
                        position: template.heroPos,
                        heroIndex: 0,
                        playerCount: template.playerStacksBb.length,
                        stacks: stacks,
                        actions: actions,
                        anteBb: template.anteBb,
                      ),
                      tags: const ['pushfold'],
                    ),
                  );
                  done = generated.length;
                  setState(() {});
                  await Future.delayed(Duration.zero);
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return AlertDialog(
              content: Text('Generated $done of $total missing spots...'),
              actions: [
                TextButton(
                  onPressed: () => cancel = true,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    TemplateCoverageUtils.recountAll(template).applyTo(template.meta);
    template.lastGeneratedAt = DateTime.now();
    return generated;
  }

  static String _firstCombo(String hand) {
    const suits = ['h', 'd', 'c', 's'];
    if (hand.length == 2) {
      final r = hand[0];
      return '$r${suits[0]} $r${suits[1]}';
    }
    final r1 = hand[0];
    final r2 = hand[1];
    final suited = hand[2] == 's';
    if (suited) return '$r1${suits[0]} $r2${suits[0]}';
    return '$r1${suits[0]} $r2${suits[1]}';
  }
}
