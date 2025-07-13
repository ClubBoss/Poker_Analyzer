import 'package:flutter/widgets.dart';

bool isCompactWidth(BuildContext context) =>
    MediaQuery.of(context).size.width < 360;
bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.shortestSide >= 600;
bool isLandscape(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape;

double responsiveSize(BuildContext context, double value) {
  if (isTablet(context)) return value * 1.5;
  if (isCompactWidth(context)) return value / 2;
  return value;
}

EdgeInsets responsiveAll(BuildContext context, double value) =>
    EdgeInsets.all(responsiveSize(context, value));
EdgeInsets responsiveSymmetric(BuildContext context,
        {double horizontal = 0, double vertical = 0}) =>
    EdgeInsets.symmetric(
      horizontal: responsiveSize(context, horizontal),
      vertical: responsiveSize(context, vertical),
    );
double paddingSize(BuildContext context, double value) =>
    responsiveSize(context, value);
EdgeInsets scaledPadding(BuildContext context, double value) =>
    EdgeInsets.all(paddingSize(context, value));
