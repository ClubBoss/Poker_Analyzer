import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_template_v2.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/hero_position.dart';

List<String> autoTags(TrainingPackTemplate template) {
  final set = <String>{};
  final positions = <HeroPosition>{template.heroPos};
  var maxPlayers = 0;
  final stacks = <int>{};
  var maxStack = 0;
  var minStack = 1 << 20;
  var flop = false;
  var turn = false;
  var river = false;
  for (final s in template.spots) {
    positions.add(s.hand.position);
    maxPlayers = s.hand.playerCount > maxPlayers ? s.hand.playerCount : maxPlayers;
    final st = s.hand.stacks['${s.hand.heroIndex}']?.round();
    if (st != null) {
      stacks.add(st);
      if (st > maxStack) maxStack = st;
      if (st < minStack) minStack = st;
    }
    final len = s.hand.board.length;
    if (len >= 3) flop = true;
    if (len >= 4) turn = true;
    if (len >= 5) river = true;
  }
  for (final p in positions) {
    if (p != HeroPosition.unknown) set.add(p.name.toUpperCase());
  }
  if (maxPlayers <= 2) {
    set.add('HU');
  } else if (maxPlayers == 3) {
    set.add('3way');
  } else {
    set.add('4way+');
  }
  for (final st in stacks) {
    set.add('${st}bb');
  }
  if (minStack <= 10) set.add('short');
  if (maxStack >= 40) set.add('deep');
  if (flop) set.add('flop');
  if (turn) set.add('turn');
  if (river) set.add('river');
  final list = set.toList();
  list.sort();
  return list;
}

List<String> autoTagsFromTemplateV2(TrainingPackTemplateV2 t) {
  final tmp = TrainingPackTemplate(
    id: t.id,
    name: t.name,
    spots: [for (final s in t.spots) TrainingPackSpot.fromJson(s.toJson())],
    heroPos: t.positions.isNotEmpty ? parseHeroPosition(t.positions.first) : HeroPosition.unknown,
    heroBbStack: t.bb,
  );
  return autoTags(tmp);
}

void _autoTagSpotsList(List<TrainingPackSpot> spots) {
  for (final spot in spots) {
    final posTag = 'pos:${spot.hand.position.name}';
    final stack = spot.hand.stacks['${spot.hand.heroIndex}'] ?? 0.0;
    final stackTag = 'bb:${stack.round()}';
    String? action;
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == spot.hand.heroIndex) {
        action = a.action;
        break;
      }
    }
    final catTag = action != null ? 'cat:$action' : null;
    final set = {...spot.tags, posTag, stackTag};
    if (catTag != null) set.add(catTag);
    spot.tags = set.toList()..sort();
    final cats = [posTag, stackTag];
    if (catTag != null) cats.add(catTag);
    spot.categories = cats;
  }
}

void autoTagSpots(TrainingPackTemplate tpl) => _autoTagSpotsList(tpl.spots);

void autoTagSpotsV2(TrainingPackTemplateV2 tpl) => _autoTagSpotsList(tpl.spots);

String buildSlug(String action, HeroPosition hero, HeroPosition villain, List<int> stacks, bool icm) {
  String a;
  switch (action) {
    case 'push':
      a = 'push';
      break;
    case 'callPush':
      a = 'call';
      break;
    case 'minraiseFold':
      a = 'minraise';
      break;
    default:
      a = action;
  }
  final avg = stacks.isEmpty ? 0 : stacks.reduce((x, y) => x + y) ~/ stacks.length;
  final prefix = icm ? 'icm-' : '';
  return '$prefix$a-${hero.name}-${avg}bb-vs-${villain.name}';
}

String uniqueSlug(String base, Set<String> used) {
  var slug = base;
  var i = 1;
  while (used.contains(slug)) {
    slug = '$base-${i++}';
  }
  used.add(slug);
  return slug;
}
