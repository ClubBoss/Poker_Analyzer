import 'package:flutter/widgets.dart';

bool isCompactWidth(BuildContext context) {
  final mq = MediaQuery.of(context);
  return mq.size.width < 360;
}

double responsiveSize(BuildContext context, double value) {
  final mq = MediaQuery.of(context);
  return mq.size.width < 360 ? value / 2 : value;
}

EdgeInsets responsiveAll(BuildContext context, double value) {
  final mq = MediaQuery.of(context);
  return EdgeInsets.all(mq.size.width < 360 ? value / 2 : value);
}

Orientation currentOrientation(BuildContext context) {
  final mq = MediaQuery.of(context);
  return mq.orientation;
}

bool isPortrait(BuildContext context) {
  final mq = MediaQuery.of(context);
  return mq.orientation == Orientation.portrait;
}

bool isLandscape(BuildContext context) {
  final mq = MediaQuery.of(context);
  return mq.orientation == Orientation.landscape;
}
