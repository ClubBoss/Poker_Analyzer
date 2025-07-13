import 'package:flutter/widgets.dart';

bool isCompactWidth(BuildContext context) => MediaQuery.of(context).size.width < 360;

double responsiveSize(BuildContext context, double value) => isCompactWidth(context) ? value / 2 : value;

EdgeInsets responsiveAll(BuildContext context, double value) => EdgeInsets.all(responsiveSize(context, value));

bool isPortrait(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.portrait;

bool isLandscape(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape;
