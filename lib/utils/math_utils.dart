/// Простейшие математические утилиты (без Flutter).
library math_utils;

/// Ограничивает значение целого числа в [min, max] (границы опциональны).
int clampInt(int value, {int? min, int? max}) {
  var v = value;
  if (min != null && v < min) v = min;
  if (max != null && v > max) v = max;
  return v;
}
