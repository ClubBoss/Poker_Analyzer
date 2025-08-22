#!/usr/bin/env bash
set -euo pipefail

fix_file() {
  f="$1"
  # 1) const перед TweenSequenceItem -> убрать
  perl -0777 -pe 's/\bconst\s+(TweenSequenceItem\s*\()/\1/g' -i "$f"
  # 2) ConstantTween(число) -> ConstantTween<double>(число)
  perl -0777 -pe 's/ConstantTween\s*\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)/ConstantTween<double>(\1)/g' -i "$f"
  # 3) const перед TweenSequence<...>[...] или перед списком -> убрать
  perl -0777 -pe 's/\bconst\s+(TweenSequence\s*<[^>]*>\s*\[)/\1/g; s/\bconst\s+\[/[/g' -i "$f"
}

fix_file lib/widgets/win_pot_animation.dart
fix_file lib/widgets/win_text_widget.dart
fix_file lib/widgets/winner_zone_highlight.dart

dart format .
dart analyze
