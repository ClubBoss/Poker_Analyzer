import 'package:flutter/widgets.dart';

import 'context_extensions.dart';

bool isCompactWidth(BuildContext context) {
  return context.mediaQuery.size.width < 360;
}

double responsiveSize(BuildContext context, double value) {
  return isCompactWidth(context) ? value / 2 : value;
}

EdgeInsets responsiveAll(BuildContext context, double value) {
  return EdgeInsets.all(isCompactWidth(context) ? value / 2 : value);
}

Orientation currentOrientation(BuildContext context) {
  return context.mediaQuery.orientation;
}

bool isPortrait(BuildContext context) {
  return context.mediaQuery.orientation == Orientation.portrait;
}

bool isLandscape(BuildContext context) {
  return context.mediaQuery.orientation == Orientation.landscape;
}
