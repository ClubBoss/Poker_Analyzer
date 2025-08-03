import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../core/training/export/training_pack_exporter_v2.dart';
import '../utils/snackbar_util.dart';

class YamlPackDiffScreen extends StatelessWidget {
  final TrainingPackTemplateV2 packA;
  final TrainingPackTemplateV2 packB;
  const YamlPackDiffScreen({super.key, required this.packA, required this.packB});

  @override
  Widget build(BuildContext context) {
    final yamlA = const TrainingPackExporterV2().exportYaml(packA);
    final yamlB = const TrainingPackExporterV2().exportYaml(packB);
    const eq = DeepCollectionEquality();
    final metaDiff = {...packA.meta.keys, ...packB.meta.keys}
        .where((k) => !eq.equals(packA.meta[k], packB.meta[k]))
        .length;
    final tagsA = {...packA.tags};
    final tagsB = {...packB.tags};
    final tagsDiff = tagsA.difference(tagsB).length + tagsB.difference(tagsA).length;
    final spotCountDiff = (packA.spotCount - packB.spotCount).abs();
    final diffColor = Colors.amber.withOpacity(.2);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yaml Diff'),
        actions: [
          IconButton(
            tooltip: 'Copy A',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: yamlA));
              SnackbarUtil.showMessage(context, 'Copied A');
            },
          ),
          IconButton(
            tooltip: 'Copy B',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: yamlB));
              SnackbarUtil.showMessage(context, 'Copied B');
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Meta diff: $metaDiff'),
            Text('Tags diff: $tagsDiff'),
            Text('Spot count diff: $spotCountDiff'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('ID A')),
                  DataColumn(label: Text('ID B')),
                  DataColumn(label: Text('EV A'), numeric: true),
                  DataColumn(label: Text('EV B'), numeric: true),
                  DataColumn(label: Text('ICM A'), numeric: true),
                  DataColumn(label: Text('ICM B'), numeric: true),
                  DataColumn(label: Text('Note A')),
                  DataColumn(label: Text('Note B')),
                  DataColumn(label: Text('Pos A')),
                  DataColumn(label: Text('Pos B')),
                  DataColumn(label: Text('Hand A')),
                  DataColumn(label: Text('Hand B')),
                ],
                rows: [
                  for (var i = 0; i < (packA.spots.length > packB.spots.length ? packA.spots.length : packB.spots.length); i++)
                    _buildRow(i, diffColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(int i, Color diffColor) {
    final a = i < packA.spots.length ? packA.spots[i] : null;
    final b = i < packB.spots.length ? packB.spots[i] : null;
    final idDiff = (a?.id ?? '') != (b?.id ?? '');
    final evDiff = (a?.heroEv ?? 0) != (b?.heroEv ?? 0);
    final icmDiff = (a?.heroIcmEv ?? 0) != (b?.heroIcmEv ?? 0);
    final noteDiff = (a?.note ?? '') != (b?.note ?? '');
    final posDiff = a?.hand.position != b?.hand.position;
    final handDiff = (a?.hand.heroCards ?? '') != (b?.hand.heroCards ?? '');
    return DataRow(
      color: idDiff ? WidgetStateProperty.all(AppColors.errorBg) : null,
      cells: [
        DataCell(Text('${i + 1}')),
        DataCell(_diffBox(a?.id ?? '', idDiff, diffColor)),
        DataCell(_diffBox(b?.id ?? '', idDiff, diffColor)),
        DataCell(_diffBox(a?.heroEv?.toStringAsFixed(2) ?? '-', evDiff, diffColor)),
        DataCell(_diffBox(b?.heroEv?.toStringAsFixed(2) ?? '-', evDiff, diffColor)),
        DataCell(_diffBox(a?.heroIcmEv?.toStringAsFixed(2) ?? '-', icmDiff, diffColor)),
        DataCell(_diffBox(b?.heroIcmEv?.toStringAsFixed(2) ?? '-', icmDiff, diffColor)),
        DataCell(_diffBox(a?.note ?? '', noteDiff, diffColor)),
        DataCell(_diffBox(b?.note ?? '', noteDiff, diffColor)),
        DataCell(_diffBox(a != null ? a.hand.position.label : '-', posDiff, diffColor)),
        DataCell(_diffBox(b != null ? b.hand.position.label : '-', posDiff, diffColor)),
        DataCell(_diffBox(a?.hand.heroCards ?? '', handDiff, diffColor)),
        DataCell(_diffBox(b?.hand.heroCards ?? '', handDiff, diffColor)),
      ],
    );
  }

  Widget _diffBox(String text, bool diff, Color diffColor) {
    return Container(
      color: diff ? diffColor : null,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(text),
    );
  }
}
