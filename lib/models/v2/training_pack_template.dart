import 'training_pack_spot.dart';
import 'hero_position.dart';
import 'focus_goal.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import '../../services/pack_generator_service.dart';
import '../../helpers/poker_position_helper.dart';

class TrainingPackTemplate {
  final String id;
  String name;
  String description;
  GameType gameType;
  List<TrainingPackSpot> spots;
  List<String> tags;
  List<String> focusTags;
  List<FocusGoal> focusHandTypes;
  int heroBbStack;
  List<int> playerStacksBb;
  HeroPosition heroPos;
  int spotCount;
  int bbCallPct;
  int anteBb;
  double minEvForCorrect;
  List<String>? heroRange;
  final DateTime createdAt;
  DateTime? lastGeneratedAt;
  Map<String, dynamic> meta;
  bool goalAchieved;
  int goalTarget;
  int goalProgress;
  String? targetStreet;
  int streetGoal;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.gameType = GameType.tournament,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
    List<String>? focusTags,
    List<FocusGoal>? focusHandTypes,
    this.heroBbStack = 10,
    List<int>? playerStacksBb,
    this.heroPos = HeroPosition.sb,
    this.spotCount = 20,
    this.bbCallPct = 20,
    this.anteBb = 0,
    this.minEvForCorrect = 0.01,
    this.heroRange,
    DateTime? createdAt,
    this.lastGeneratedAt,
    Map<String, dynamic>? meta,
    this.goalAchieved = false,
    this.goalTarget = 0,
    this.goalProgress = 0,
    this.targetStreet,
    this.streetGoal = 0,
  })  : spots = spots ?? [],
        tags = tags ?? [],
        focusTags = focusTags ?? [],
        focusHandTypes = focusHandTypes ?? [],
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
    List<String>? focusTags,
    List<FocusGoal>? focusHandTypes,
    int? heroBbStack,
    List<int>? playerStacksBb,
    HeroPosition? heroPos,
    int? spotCount,
    int? bbCallPct,
    int? anteBb,
    double? minEvForCorrect,
    List<String>? heroRange,
    DateTime? createdAt,
    DateTime? lastGeneratedAt,
    Map<String, dynamic>? meta,
    bool? goalAchieved,
    int? goalTarget,
    int? goalProgress,
    String? targetStreet,
    int? streetGoal,
  }) {
    return TrainingPackTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      spots: spots ?? List<TrainingPackSpot>.from(this.spots),
      tags: tags ?? List<String>.from(this.tags),
      focusTags: focusTags ?? List<String>.from(this.focusTags),
      focusHandTypes: focusHandTypes ?? List<FocusGoal>.from(this.focusHandTypes),
      heroBbStack: heroBbStack ?? this.heroBbStack,
      playerStacksBb: playerStacksBb ?? List<int>.from(this.playerStacksBb),
      heroPos: heroPos ?? this.heroPos,
      spotCount: spotCount ?? this.spotCount,
      bbCallPct: bbCallPct ?? this.bbCallPct,
      anteBb: anteBb ?? this.anteBb,
      minEvForCorrect: minEvForCorrect ?? this.minEvForCorrect,
      heroRange: heroRange ?? this.heroRange,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      meta: meta ?? Map<String, dynamic>.from(this.meta),
      goalAchieved: goalAchieved ?? this.goalAchieved,
      goalTarget: goalTarget ?? this.goalTarget,
      goalProgress: goalProgress ?? this.goalProgress,
      targetStreet: targetStreet ?? this.targetStreet,
      streetGoal: streetGoal ?? this.streetGoal,
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
      focusTags: [for (final t in (json['focusTags'] as List? ?? [])) t as String],
      focusHandTypes: [
        for (final t in (json['focusHandTypes'] as List? ?? []))
          FocusGoal.fromJson(t)
      ],
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
      minEvForCorrect: (json['minEvForCorrect'] as num?)?.toDouble() ?? 0.01,
      heroRange: (json['heroRange'] as List?)?.map((e) => e as String).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastGeneratedAt:
          DateTime.tryParse(json['lastGeneratedAt'] as String? ?? ''),
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : {},
      goalAchieved: json['goalAchieved'] as bool? ?? false,
      goalTarget: json['goalTarget'] as int? ?? 0,
      goalProgress: json['goalProgress'] as int? ?? 0,
      targetStreet: json['targetStreet'] as String?,
      streetGoal: json['streetGoal'] as int? ?? 0,
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
        if (focusTags.isNotEmpty) 'focusTags': focusTags,
        if (focusHandTypes.isNotEmpty)
          'focusHandTypes': [for (final g in focusHandTypes) g.toString()],
        if (heroRange != null) 'heroRange': heroRange,
        'heroBbStack': heroBbStack,
        'playerStacksBb': playerStacksBb,
        'heroPos': heroPos.name,
        'spotCount': spotCount,
        'bbCallPct': bbCallPct,
        'anteBb': anteBb,
        'minEvForCorrect': minEvForCorrect,
        'createdAt': createdAt.toIso8601String(),
        if (lastGeneratedAt != null)
          'lastGeneratedAt': lastGeneratedAt!.toIso8601String(),
        if (meta.isNotEmpty) 'meta': meta,
        if (goalAchieved) 'goalAchieved': true,
        if (goalTarget > 0) 'goalTarget': goalTarget,
        if (goalProgress > 0) 'goalProgress': goalProgress,
        if (targetStreet != null) 'targetStreet': targetStreet,
        if (streetGoal > 0) 'streetGoal': streetGoal,
      };

  int get evCovered => meta['evCovered'] as int? ?? 0;
  int get icmCovered => meta['icmCovered'] as int? ?? 0;

  String posRangeLabel() {
    final heroSet = <HeroPosition>{heroPos};
    final oppSet = <HeroPosition>{};
    for (final s in spots) {
      heroSet.add(s.hand.position);
      final n = s.hand.playerCount;
      if (n < 2) continue;
      final order = getPositionList(n);
      final enums = [for (final o in order) parseHeroPosition(o)];
      final heroIdx = s.hand.heroIndex;
      final idx = enums.indexOf(s.hand.position);
      if (idx == -1) continue;
      final btn = (heroIdx - idx + n) % n;
      for (int i = 0; i < n; i++) {
        if (i == heroIdx) continue;
        final pos = enums[(i - btn + n) % n];
        oppSet.add(pos);
      }
    }
    List<HeroPosition> sort(Set<HeroPosition> set) {
      final list = set.toList();
      list.sort((a, b) =>
          kPositionOrder.indexOf(a).compareTo(kPositionOrder.indexOf(b)));
      return list;
    }
    final heroes = sort(heroSet);
    final opps = sort(oppSet);
    if (heroes.length == 1 && opps.isNotEmpty) {
      return '${heroes.first.label} vs ${opps.map((e) => e.label).join('+')}';
    }
    return heroes.map((e) => e.label).join('+');
  }

  void recountCoverage([List<TrainingPackSpot>? all]) {
    final list = all ?? spots;
    int ev = 0;
    int icm = 0;
    for (final s in list) {
      if (!s.dirty && s.heroEv != null) ev++;
      if (!s.dirty && s.heroIcmEv != null) icm++;
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
    final spots = tpl.spots.take(spotCount).toList();
    recountCoverage([...this.spots, ...spots]);
    return spots;
  }

  String handTypeSummary() {
    final ranks = '23456789TJQKA';
    final List<String> hands = heroRange ??
        [
          for (final s in spots)
            s.hand.heroCards.length >= 4
                ? '${s.hand.heroCards[0]}${s.hand.heroCards[2]}'
                : ''
        ].where((e) => e.isNotEmpty).toList();
    final set = <String>{};
    for (final h in hands) {
      if (h.length < 2) continue;
      if (h.length == 2 && h[0] == h[1]) {
        final v = ranks.indexOf(h[0]) + 2;
        if (v <= 6) {
          set.add('small pairs');
        } else if (v <= 10) {
          set.add('mid pairs');
        } else {
          set.add('big pairs');
        }
      } else if (h.length == 3 && h[2] == 's') {
        if (h[0] == 'A') set.add('AXs');
        if (h[0] == 'K') set.add('KXs');
        if (h[0] == 'Q') set.add('QXs');
      }
    }
    final list = set.toList();
    list.sort();
    return list.join(', ');
  }

}
