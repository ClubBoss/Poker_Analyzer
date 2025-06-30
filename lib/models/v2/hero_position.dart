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
