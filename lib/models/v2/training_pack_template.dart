import 'training_pack_spot.dart';
import 'hero_position.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import '../../services/pack_generator_service.dart';
import '../../services/push_fold_ev_service.dart';
import '../action_entry.dart';
import 'hand_data.dart';
import 'package:flutter/material.dart';

class TrainingPackTemplate {
  final String id;
  String name;
  String description;
  GameType gameType;
  List<TrainingPackSpot> spots;
  List<String> tags;
  int heroBbStack;
  List<int> playerStacksBb;
  HeroPosition heroPos;
  int spotCount;
  int bbCallPct;
  int anteBb;
  List<String>? heroRange;
  final DateTime createdAt;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.gameType = GameType.tournament,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
    this.heroBbStack = 10,
    List<int>? playerStacksBb,
    this.heroPos = HeroPosition.sb,
    this.spotCount = 20,
    this.bbCallPct = 20,
    this.anteBb = 0,
    this.heroRange,
    DateTime? createdAt,
  })  : spots = spots ?? [],
        tags = tags ?? [],
        playerStacksBb = playerStacksBb ?? const [10, 10],
        createdAt = createdAt ?? DateTime.now();

  TrainingPackTemplate copyWith({
    String? id,
    String? name,
    String? description,
    GameType? gameType,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
    int? heroBbStack,
    List<int>? playerStacksBb,
    HeroPosition? heroPos,
    int? spotCount,
    int? bbCallPct,
    int? anteBb,
    List<String>? heroRange,
    DateTime? createdAt,
  }) {
    return TrainingPackTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      spots: spots ?? List<TrainingPackSpot>.from(this.spots),
      tags: tags ?? List<String>.from(this.tags),
      heroBbStack: heroBbStack ?? this.heroBbStack,
      playerStacksBb: playerStacksBb ?? List<int>.from(this.playerStacksBb),
      heroPos: heroPos ?? this.heroPos,
      spotCount: spotCount ?? this.spotCount,
      bbCallPct: bbCallPct ?? this.bbCallPct,
      anteBb: anteBb ?? this.anteBb,
      heroRange: heroRange ?? this.heroRange,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gameType: parseGameType(json['gameType']),
      spots: [
        for (final s in (json['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s))
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
      heroBbStack: json['heroBbStack'] as int? ?? 10,
      playerStacksBb: [
        for (final v in (json['playerStacksBb'] as List? ?? [10, 10]))
          (v as num).toInt()
      ],
      heroPos: HeroPosition.values.firstWhere(
        (e) => e.name == json['heroPos'],
        orElse: () => HeroPosition.sb,
      ),
      spotCount: json['spotCount'] as int? ?? 20,
      bbCallPct: json['bbCallPct'] as int? ?? 20,
      anteBb: json['anteBb'] as int? ?? 0,
      heroRange: (json['heroRange'] as List?)?.map((e) => e as String).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'gameType': gameType.name,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        if (tags.isNotEmpty) 'tags': tags,
        if (heroRange != null) 'heroRange': heroRange,
        'heroBbStack': heroBbStack,
        'playerStacksBb': playerStacksBb,
        'heroPos': heroPos.name,
        'spotCount': spotCount,
        'bbCallPct': bbCallPct,
        'anteBb': anteBb,
        'createdAt': createdAt.toIso8601String(),
      };

  Future<List<TrainingPackSpot>> generateSpots() async {
    final range = heroRange ?? PackGeneratorService.topNHands(25).toList();
    final tpl = await PackGeneratorService.generatePushFoldPack(
      id: id,
      name: name,
      heroBbStack: heroBbStack,
      playerStacksBb: playerStacksBb,
      heroPos: heroPos,
      heroRange: range,
      bbCallPct: bbCallPct,
      anteBb: anteBb,
    );
    return tpl.spots.take(spotCount).toList();
  }

  Future<List<TrainingPackSpot>> generateSpotsWithProgress(
      BuildContext context) async {
    final range = heroRange ?? PackGeneratorService.topNHands(25).toList();
    final total = spotCount;
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
                final isHu = playerStacksBb.length == 2;
                const idxBB = 1;
                final callCutoff =
                    (PackGeneratorService.handRanking.length * bbCallPct / 100)
                        .round();
                for (var i = 0;
                    i < range.length && generated.length < total;
                    i++) {
                  if (cancel) break;
                  final hand = range[i];
                  final heroCards = _firstCombo(hand);
                  final actions = {
                    0: [
                      ActionEntry(0, 0, 'push', amount: heroBbStack.toDouble()),
                      for (var j = 1; j < playerStacksBb.length; j++)
                        if (isHu &&
                            j == idxBB &&
                            PackGeneratorService.handRanking.indexOf(hand) <
                                callCutoff)
                          ActionEntry(0, j, 'call',
                              amount: heroBbStack.toDouble())
                        else
                          ActionEntry(0, j, 'fold'),
                    ]
                  };
                  final ev = computePushEV(
                    heroBbStack: heroBbStack,
                    bbCount: playerStacksBb.length - 1,
                    heroHand: hand,
                    anteBb: anteBb,
                  );
                  actions[0]![0].ev = ev;
                  final stacks = {
                    for (var j = 0; j < playerStacksBb.length; j++)
                      '$j': playerStacksBb[j].toDouble()
                  };
                  generated.add(
                    TrainingPackSpot(
                      id: '${id}_${spots.length + generated.length + 1}',
                      title: '$hand push',
                      hand: HandData(
                        heroCards: heroCards,
                        position: heroPos,
                        heroIndex: 0,
                        playerCount: playerStacksBb.length,
                        stacks: stacks,
                        actions: actions,
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
              content: Text('Generating $done of $total spots…'),
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
