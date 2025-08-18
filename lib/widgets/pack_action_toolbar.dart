import 'package:flutter/material.dart';

class PackActionToolbar extends StatelessWidget {
  final VoidCallback? onImportCsv;
  final VoidCallback? onExportMarkdown;
  final VoidCallback? onExportPdf;
  const PackActionToolbar({
    super.key,
    this.onImportCsv,
    this.onExportMarkdown,
    this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: onImportCsv, child: const Text('Импорт CSV')),
        ElevatedButton(
          onPressed: onExportMarkdown,
          child: const Text('Экспорт MD'),
        ),
        ElevatedButton(
          onPressed: onExportPdf,
          child: const Text('Экспорт PDF'),
        ),
      ],
    );
  }
}
