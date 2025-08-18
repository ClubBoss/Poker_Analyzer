import 'package:flutter/material.dart';

class FilterSummary extends StatelessWidget {
  final String summary;
  const FilterSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(summary, style: const TextStyle(color: Colors.white60)),
    );
  }
}
