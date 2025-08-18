import 'package:flutter/material.dart';

/// Displays a tag with its usage count. Tapping toggles selection to filter
/// session stats by a specific tag.
class SessionTagRow extends StatelessWidget {
  final String tag;
  final int count;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  const SessionTagRow({
    super.key,
    required this.tag,
    required this.count,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final style = TextStyle(
      color: selected ? accent : Colors.white,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
    );

    final content = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tag, style: style.copyWith(fontSize: 14 * scale)),
              SizedBox(height: 4 * scale),
              Text(
                count.toString(),
                style: style.copyWith(fontSize: 14 * scale),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(tag, style: style.copyWith(fontSize: 14 * scale)),
            ),
            Text(count.toString(), style: style.copyWith(fontSize: 14 * scale)),
          ],
        );
      },
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12 * scale),
        child: content,
      ),
    );
  }
}
