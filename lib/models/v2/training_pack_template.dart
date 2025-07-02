import 'training_pack_spot.dart';
import 'hero_position.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import '../../services/pack_generator_service.dart';
import '../../services/push_fold_ev_service.dart';
import '../action_entry.dart';
import 'hand_data.dart';
import '../../helpers/hand_utils.dart';
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
  DateTime? lastGeneratedAt;
  Map<String, dynamic> meta;

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
    this.lastGeneratedAt,
    Map<String, dynamic>? meta,
  })  : spots = spots ?? [],
        tags = tags ?? [],
        playerStacksBb = playerStacksBb ?? const [10, 10],
        meta = meta ?? {},
        createdAt = createdAt ?? DateTime.now() {
    recountCoverage();
  }

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
    DateTime? lastGeneratedAt,
    Map<String, dynamic>? meta,
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
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      meta: meta ?? Map<String, dynamic>.from(this.meta),
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    final tpl = TrainingPackTemplate(
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
      lastGeneratedAt:
          DateTime.tryParse(json['lastGeneratedAt'] as String? ?? ''),
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : {},
    );
    if (!tpl.meta.containsKey('evCovered') || !tpl.meta.containsKey('icmCovered')) {
      tpl.recountCoverage();
    }
    return tpl;
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
        if (lastGeneratedAt != null)
          'lastGeneratedAt': lastGeneratedAt!.toIso8601String(),
        if (meta.isNotEmpty) 'meta': meta,
      };

  int get evCovered => meta['evCovered'] as int? ?? 0;
  int get icmCovered => meta['icmCovered'] as int? ?? 0;

  void recountCoverage([List<TrainingPackSpot>? all]) {
    final list = all ?? spots;
    int ev = 0;
    int icm = 0;
    for (final s in list) {
      if (s.heroEv != null) ev++;
      if (s.heroIcmEv != null) icm++;
    }
    meta['evCovered'] = ev;
    meta['icmCovered'] = icm;
  }

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
    debugPrint(
        'templateId: $id, heroBbStack: $heroBbStack, playerStacksBb: $playerStacksBb, heroPos: ${heroPos.name}, spotCount: $spotCount, bbCallPct: $bbCallPct, heroRange: ${heroRange ?? 'null'}');
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
    lastGeneratedAt = DateTime.now();
    return generated;
  }

  Future<List<TrainingPackSpot>> generateMissingSpotsWithProgress(
      BuildContext context) async {
    final existing = <String>{
      for (final s in spots)
        if (handCode(s.hand.heroCards) != null) handCode(s.hand.heroCards)!
    };
    if (existing.length >= spotCount) return [];
    final range = (heroRange ?? PackGeneratorService.topNHands(25).toList())
        .where((h) => !existing.contains(h))
        .toList();
    final total = spotCount - existing.length;
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
              content:
                  Text('Generated $done of $total missing spots…'),
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
    lastGeneratedAt = DateTime.now();
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
