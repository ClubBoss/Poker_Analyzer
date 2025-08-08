import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TheoryLinkConfigService {
  TheoryLinkConfigService._() : notifier = ValueNotifier(TheoryLinkConfig.defaults);
  static final TheoryLinkConfigService instance = TheoryLinkConfigService._();

  final ValueNotifier<TheoryLinkConfig> notifier;
  TheoryLinkConfig get value => notifier.value;

  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    final c = TheoryLinkConfig(
      maxPerModule: prefs.getInt('theory.maxPerModule') ?? 3,
      maxPerPack: prefs.getInt('theory.maxPerPack') ?? 2,
      maxPerSpot: prefs.getInt('theory.maxPerSpot') ?? 2,
      noveltyRecent: Duration(hours: prefs.getInt('theory.noveltyRecentHours') ?? 72),
      noveltyMinOverlap: prefs.getDouble('theory.noveltyMinOverlap') ?? 0.6,
      wTag: prefs.getDouble('theory.weight.tag') ?? 0.2,
      wErr: prefs.getDouble('theory.weight.errorRate') ?? 0.5,
      wDecay: prefs.getDouble('theory.weight.decay') ?? 0.3,
      ablationEnabled: prefs.getBool('theory.ablation') ?? false,
      perSessionCap: prefs.getInt('theory.cap.session') ?? 4,
      perDayCap: prefs.getInt('theory.cap.day') ?? 8,
      perTagCooldownHours: prefs.getInt('theory.tag.cooldownHours') ?? 24,
    );
    notifier.value = c;
  }
}

class TheoryLinkConfig {
  final int maxPerModule, maxPerPack, maxPerSpot;
  final Duration noveltyRecent;
  final double noveltyMinOverlap;
  final double wTag, wErr, wDecay;
  final bool ablationEnabled;
  final int perSessionCap;
  final int perDayCap;
  final int perTagCooldownHours;

  const TheoryLinkConfig({
    required this.maxPerModule,
    required this.maxPerPack,
    required this.maxPerSpot,
    required this.noveltyRecent,
    required this.noveltyMinOverlap,
    required this.wTag,
    required this.wErr,
    required this.wDecay,
    required this.ablationEnabled,
    required this.perSessionCap,
    required this.perDayCap,
    required this.perTagCooldownHours,
  });

  static const TheoryLinkConfig defaults = TheoryLinkConfig(
    maxPerModule: 3,
    maxPerPack: 2,
    maxPerSpot: 2,
    noveltyRecent: Duration(hours: 72),
    noveltyMinOverlap: 0.6,
    wTag: 0.2,
    wErr: 0.5,
    wDecay: 0.3,
    ablationEnabled: false,
    perSessionCap: 4,
    perDayCap: 8,
    perTagCooldownHours: 24,
  );
}
