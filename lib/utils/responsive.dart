import 'package:flutter/widgets.dart';

bool isCompactWidth(BuildContext context) => MediaQuery.of(context).size.width < 360;

double responsiveSize(BuildContext context, double value) => isCompactWidth(context) ? value / 2 : value;

EdgeInsets responsiveAll(BuildContext context, double value) => EdgeInsets.all(responsiveSize(context, value));

EdgeInsets responsiveSymmetric(
  BuildContext context, {
  double vertical = 0,
  double horizontal = 0,
}) =>
    EdgeInsets.symmetric(
      vertical: responsiveSize(context, vertical),
      horizontal: responsiveSize(context, horizontal),
    );

Orientation currentOrientation(BuildContext context) =>
    MediaQuery.of(context).orientation;

bool isPortrait(BuildContext context) =>
    currentOrientation(context) == Orientation.portrait;

bool isLandscape(BuildContext context) =>
    currentOrientation(context) == Orientation.landscape;
