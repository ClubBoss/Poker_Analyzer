import 'package:flutter/material.dart';

/// Displays a single statistic as a responsive row with a label and value.
///
/// On narrow layouts (<360px) the label and value are stacked vertically to
/// preserve space. A tap callback can be supplied for interactive rows.
class SessionStatRow extends StatelessWidget {
  final String label;
  final String value;
  final double scale;
  final VoidCallback? onTap;

  const SessionStatRow({
    super.key,
    required this.label,
    required this.value,
    required this.scale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 360) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
            SizedBox(height: 4 * scale),
            Text(value,
                style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
          ],
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
          ),
          Text(value,
              style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
        ],
      );
    });

    final row = Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: child,
    );
    return onTap != null ? InkWell(onTap: onTap, child: row) : row;
  }
}
