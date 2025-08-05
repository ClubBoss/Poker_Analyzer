import 'training_pack_spot.dart';
import 'hero_position.dart';
import 'focus_goal.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import 'training_pack_variant.dart';
import '../../services/pack_generator_service.dart';
import '../../helpers/poker_position_helper.dart';
import '../../utils/template_coverage_utils.dart';
import '../copy_with_mixin.dart';

class TrainingPackTemplate with CopyWithMixin<TrainingPackTemplate> {
  final String id;
  String slug;
  String name;
  String description;
  String goal;
  String category;
  GameType gameType;
  List<TrainingPackSpot> spots;
  List<String> tags;
  List<String> focusTags;
  List<FocusGoal> focusHandTypes;
  List<String> requiredBoardClusters;
  List<String> excludedBoardClusters;
  String? difficulty;
  int get difficultyLevel => int.tryParse(difficulty ?? '') ?? 0;
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
  DateTime? lastTrainedAt;
  Map<String, dynamic> meta;
  bool goalAchieved;
  int goalTarget;
  int goalProgress;
  String? targetStreet;
  int streetGoal;
  bool isDraft;
  bool isBuiltIn;
  String? png;
  bool? isFavorite;
  bool isPinned;
  bool trending;
  bool recommended;

  TrainingPackTemplate({
    required this.id,
    this.slug = '',
    required this.name,
    this.description = '',
    this.goal = '',
    this.category = '',
    this.gameType = GameType.tournament,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
    List<String>? focusTags,
    List<FocusGoal>? focusHandTypes,
    List<String>? requiredBoardClusters,
    List<String>? excludedBoardClusters,
    this.difficulty,
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
    this.lastTrainedAt,
    Map<String, dynamic>? meta,
    this.goalAchieved = false,
    this.goalTarget = 0,
    this.goalProgress = 0,
    this.targetStreet,
    this.streetGoal = 0,
    this.isDraft = false,
    this.isBuiltIn = false,
    this.png,
    this.isFavorite = false,
    this.isPinned = false,
    this.trending = false,
    this.recommended = false,
  }) : spots = spots ?? [],
       tags = tags ?? [],
       focusTags = focusTags ?? [],
       focusHandTypes = focusHandTypes ?? [],
       requiredBoardClusters = requiredBoardClusters ?? [],
       excludedBoardClusters = excludedBoardClusters ?? [],
       playerStacksBb = playerStacksBb ?? const [10, 10],
       meta = meta ?? {},
       createdAt = createdAt ?? DateTime.now() {
    TemplateCoverageUtils.recountAll(this).applyTo(this.meta);
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    final tpl = TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      category: json['category'] as String? ?? '',
      gameType: parseGameType(json['gameType']),
      spots: [
        for (final s in (json['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s)),
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
      focusTags: [
        for (final t in (json['focusTags'] as List? ?? [])) t as String,
      ],
      focusHandTypes: [
        for (final t in (json['focusHandTypes'] as List? ?? []))
          FocusGoal.fromJson(t),
      ],
      requiredBoardClusters: [
        for (final c in (json['requiredBoardClusters'] as List? ?? []))
          c as String,
      ],
      excludedBoardClusters: [
        for (final c in (json['excludedBoardClusters'] as List? ?? []))
          c as String,
      ],
      difficulty: json['difficulty'] as String?,
      heroBbStack: json['heroBbStack'] as int? ?? 10,
      playerStacksBb: [
        for (final v in (json['playerStacksBb'] as List? ?? [10, 10]))
          (v as num).toInt(),
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
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastGeneratedAt: DateTime.tryParse(
        json['lastGeneratedAt'] as String? ?? '',
      ),
      lastTrainedAt: DateTime.tryParse(json['lastTrainedAt'] as String? ?? ''),
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : {},
      goalAchieved: json['goalAchieved'] as bool? ?? false,
      goalTarget: json['goalTarget'] as int? ?? 0,
      goalProgress: json['goalProgress'] as int? ?? 0,
      targetStreet: json['targetStreet'] as String?,
      streetGoal: json['streetGoal'] as int? ?? 0,
      isDraft: json['isDraft'] as bool? ?? false,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      png: json['png'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      trending: json['trending'] as bool? ?? false,
      recommended: json['recommended'] as bool? ?? false,
    );
    if (!tpl.meta.containsKey('evCovered') ||
        !tpl.meta.containsKey('icmCovered')) {
      TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    }
    return tpl;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'description': description,
    if (goal.isNotEmpty) 'goal': goal,
    'category': category,
    'gameType': gameType.name,
    if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
    if (tags.isNotEmpty) 'tags': tags,
    if (focusTags.isNotEmpty) 'focusTags': focusTags,
    if (focusHandTypes.isNotEmpty)
      'focusHandTypes': [for (final g in focusHandTypes) g.toString()],
    if (requiredBoardClusters.isNotEmpty)
      'requiredBoardClusters': requiredBoardClusters,
    if (excludedBoardClusters.isNotEmpty)
      'excludedBoardClusters': excludedBoardClusters,
    if (heroRange != null) 'heroRange': heroRange,
    if (difficulty != null) 'difficulty': difficulty,
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
    if (lastTrainedAt != null)
      'lastTrainedAt': lastTrainedAt!.toIso8601String(),
    if (meta.isNotEmpty) 'meta': meta,
    if (goalAchieved) 'goalAchieved': true,
    if (goalTarget > 0) 'goalTarget': goalTarget,
    if (goalProgress > 0) 'goalProgress': goalProgress,
    if (targetStreet != null) 'targetStreet': targetStreet,
    if (streetGoal > 0) 'streetGoal': streetGoal,
    if (isDraft) 'isDraft': true,
    if (isBuiltIn) 'isBuiltIn': true,
    if (png != null) 'png': png,
    if (isFavorite == true) 'isFavorite': true,
    if (isPinned) 'isPinned': true,
    if (trending) 'trending': true,
    if (recommended) 'recommended': true,
  };

  @override
  TrainingPackTemplate Function(Map<String, dynamic> json) get fromJson =>
      TrainingPackTemplate.fromJson;

  int get evCovered => meta['evCovered'] as int? ?? 0;
  int get icmCovered => meta['icmCovered'] as int? ?? 0;
  int get totalWeight => meta['totalWeight'] as int? ?? spots.length;
  double? get coveragePercent {
    final total = totalWeight;
    if (total == 0) return null;
    return (evCovered + icmCovered) * 100 / (2 * total);
  }

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
      list.sort(
        (a, b) =>
            kPositionOrder.indexOf(a).compareTo(kPositionOrder.indexOf(b)),
      );
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
    TemplateCoverageUtils.recountAll(this).applyTo(this.meta);
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
    return spots;
  }

  String handTypeSummary() {
    const ranks = '23456789TJQKA';
    final List<String> hands =
        heroRange ??
        [
          for (final s in spots)
            s.hand.heroCards.length >= 4
                ? '${s.hand.heroCards[0]}${s.hand.heroCards[2]}'
                : '',
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

  List<TrainingPackVariant> playableVariants({bool groupByPosition = false}) {
    final list = <TrainingPackVariant>[];
    final raw = meta['variants'];
    if (raw is List) {
      for (final v in raw) {
        final variant = v is TrainingPackVariant
            ? v
            : TrainingPackVariant.fromJson(Map<String, dynamic>.from(v));
        if (variant.rangeId != null) list.add(variant);
      }
    }
    if (groupByPosition && list.length > 1) {
      final items = list.asMap().entries.toList();
      items.sort((a, b) {
        final pa = kPositionOrder.indexOf(a.value.position);
        final pb = kPositionOrder.indexOf(b.value.position);
        if (pa == pb) return a.key.compareTo(b.key);
        return pa.compareTo(pb);
      });
      return [for (final e in items) e.value];
    }
    return list;
  }

  Set<String> playableRangeIds() {
    return {
      for (final v in playableVariants())
        if (v.rangeId != null) v.rangeId!,
    };
  }

  bool hasPlayableContent() => playableVariants().isNotEmpty;
}

extension TrainingPackTemplateUpdated on TrainingPackTemplate {
  DateTime? get updatedDate {
    final u = meta['updated'];
    if (u is String) return DateTime.tryParse(u);
    if (u is int) return DateTime.fromMillisecondsSinceEpoch(u);
    try {
      final dynamic d = this;
      if (d.updatedAt is DateTime) return d.updatedAt as DateTime;
      if (d.lastModified is DateTime) return d.lastModified as DateTime;
    } catch (_) {}
    return null;
  }
}

extension TrainingPackTemplateStreetCoverage on TrainingPackTemplate {
  List<int> streetTotals() {
    final totals = List<int>.filled(4, 0);
    for (final s in spots) {
      totals[s.street]++;
    }
    return totals;
  }

  List<int> streetCovered() {
    final covered = List<int>.filled(4, 0);
    for (final s in spots) {
      if (s.heroEv != null && s.heroIcmEv != null) {
        covered[s.street]++;
      }
    }
    return covered;
  }
}
