import 'dart:math';

import 'hand_data.dart';
import 'hero_position.dart';
import 'training_pack_spot.dart';

class DynamicSpotTemplate {
  final List<String> handPool;
  final String villainAction;
  final List<String> heroOptions;
  final HeroPosition position;
  final int playerCount;
  final int stack;
  final int sampleSize;

  const DynamicSpotTemplate({
    required this.handPool,
    required this.villainAction,
    required this.heroOptions,
    required this.position,
    required this.playerCount,
    required this.stack,
    required this.sampleSize,
  });

  factory DynamicSpotTemplate.fromJson(Map<String, dynamic> j) {
    return DynamicSpotTemplate(
      handPool: [for (final h in (j['handPool'] as List? ?? [])) h.toString()],
      villainAction: j['villainAction']?.toString() ?? '',
      heroOptions: [for (final o in (j['heroOptions'] as List? ?? [])) o.toString()],
      position: parseHeroPosition(j['position']?.toString() ?? ''),
      playerCount: (j['playerCount'] as num?)?.toInt() ?? 2,
      stack: (j['stack'] as num?)?.toInt() ?? 0,
      sampleSize: (j['sampleSize'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'handPool': handPool,
        'villainAction': villainAction,
        if (heroOptions.isNotEmpty) 'heroOptions': heroOptions,
        'position': position.name,
        'playerCount': playerCount,
        'stack': stack,
        'sampleSize': sampleSize,
      };

  List<TrainingPackSpot> generateSpots() {
    final rng = Random();
    final pool = List<String>.from(handPool);
    pool.shuffle(rng);
    final count = sampleSize.clamp(1, pool.length);
    final spots = <TrainingPackSpot>[];
    for (final hand in pool.take(count)) {
      final handId = hand.replaceAll(' ', '');
      final id =
          '${position.name.toUpperCase()}_${handId}_vs_${villainAction.replaceAll(' ', '')}';
      final title = '${position.name.toUpperCase()} $hand vs $villainAction';
      final stacks = {
        for (var i = 0; i < playerCount; i++) '$i': stack.toDouble()
      };
      final hd = HandData(
        heroCards: hand,
        position: position,
        heroIndex: 0,
        playerCount: playerCount,
        stacks: stacks,
      );
      spots.add(TrainingPackSpot(
        id: id,
        title: title,
        villainAction: villainAction,
        heroOptions: List<String>.from(heroOptions),
        hand: hd,
      ));
    }
    return spots;
  }
}
