// ASCII-only; pure Dart (no Flutter deps)

import 'live_context.dart';

/// Returns deterministic tags describing the given [LiveContext].
/// Order (include only when true/non-zero):
/// 1) announce
/// 2) straddle
/// 3) bomb_ante
/// 4) limpers:<N>
/// 5) rake:<drop|time>
/// 6) speed:<slow|normal|fast>
/// 7) avg_bb:<N>
List<String> liveContextTags(LiveContext ctx) {
  final tags = <String>[];

  if (ctx.announceRequired) tags.add('announce');
  if (ctx.hasStraddle) tags.add('straddle');
  if (ctx.bombAnte) tags.add('bomb_ante');
  if (ctx.multiLimpers > 0) tags.add('limpers:${ctx.multiLimpers}');

  if (ctx.rakeType == 'drop' || ctx.rakeType == 'time') {
    tags.add('rake:${ctx.rakeType}');
  }

  if (ctx.tableSpeed.isNotEmpty) {
    tags.add('speed:${ctx.tableSpeed}');
  }

  if (ctx.avgStackBb > 0) tags.add('avg_bb:${ctx.avgStackBb}');

  return tags;
}

/// Joins [liveContextTags] by ", ".
String liveContextSubtitle(LiveContext ctx) => liveContextTags(ctx).join(', ');
