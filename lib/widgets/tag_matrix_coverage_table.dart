import 'package:flutter/material.dart';

import '../services/matrix_tag_config_service.dart';
import '../services/tag_matrix_coverage_service.dart';
import '../theme/app_colors.dart';

class TagMatrixCoverageTable extends StatelessWidget {
  final List<MatrixAxis> axes;
  final Map<String, Map<String, TagMatrixCellData>> data;
  final int max;

  const TagMatrixCoverageTable({
    super.key,
    required this.axes,
    required this.data,
    required this.max,
  });

  Color _color(int n) {
    if (n == 0) return Colors.black26;
    if (n == 1) return Colors.orange.withOpacity(.4);
    final t = n / max;
    return Color.lerp(Colors.blueGrey.shade300, Colors.greenAccent, t)!;
  }

  Future<void> _show(BuildContext context, String x, String y) async {
    final list = data[x]?[y]?.packs ?? [];
    if (list.isEmpty) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('$x · $y'),
        content: SizedBox(
          width: 300,
          child: ListView(shrinkWrap: true, children: [for (final p in list) Text(p)]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  DataRow _row(BuildContext context, String x) {
    final yVals = axes[1].values;
    return DataRow(cells: [
      DataCell(Text(x)),
      ...[
        for (final y in yVals)
          DataCell(GestureDetector(
            onTap: () => _show(context, x, y),
            child: Container(
              color: _color(data[x]?[y]?.count ?? 0),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Text('${data[x]?[y]?.count ?? 0}'),
            ),
          )),
      ]
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (axes.length < 2) return const SizedBox.shrink();
    final xVals = axes[0].values;
    final yVals = axes[1].values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(axes[0].name)),
          ...[for (final y in yVals) DataColumn(label: Text(y))]
        ],
        rows: [for (final x in xVals) _row(context, x)],
      ),
    );
  }
}
