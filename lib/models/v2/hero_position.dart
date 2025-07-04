enum HeroPosition { sb, bb, utg, mp, co, btn, unknown }

extension HeroPositionLabel on HeroPosition {
  String get label {
    switch (this) {
      case HeroPosition.sb:
        return 'SB';
      case HeroPosition.bb:
        return 'BB';
      case HeroPosition.utg:
        return 'UTG';
      case HeroPosition.mp:
        return 'MP';
      case HeroPosition.co:
        return 'CO';
      case HeroPosition.btn:
        return 'BTN';
      case HeroPosition.unknown:
        return 'Other';
    }
  }
}

HeroPosition parseHeroPosition(String s) {
  final p = s.toUpperCase();
  if (p.startsWith('SB')) return HeroPosition.sb;
  if (p.startsWith('BB')) return HeroPosition.bb;
  if (p.startsWith('BTN')) return HeroPosition.btn;
  if (p.startsWith('CO')) return HeroPosition.co;
  if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
  if (p.startsWith('UTG')) return HeroPosition.utg;
  return HeroPosition.unknown;
}

const kPositionOrder = [
  HeroPosition.utg,
  HeroPosition.mp,
  HeroPosition.co,
  HeroPosition.btn,
  HeroPosition.sb,
  HeroPosition.bb,
];
