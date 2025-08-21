import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/autogen_pack_error_classifier_service.dart';
import '../services/file_saver_service.dart';

/// Displays recent autogen errors with classification details.
class AutogenErrorInspectorWidget extends StatefulWidget {
  const AutogenErrorInspectorWidget({super.key});

  @override
  State<AutogenErrorInspectorWidget> createState() =>
      _AutogenErrorInspectorWidgetState();
}

class _AutogenErrorInspectorWidgetState
    extends State<AutogenErrorInspectorWidget> {
  AutogenPackErrorType? _filter;

  Future<void> _exportCsv(List<AutogenPackErrorEntry> entries) async {
    final buffer = StringBuffer('timestamp,packId,errorType,message\n');
    for (final e in entries) {
      final ts = e.timestamp.toIso8601String();
      final msg = e.message.replaceAll('\n', ' ').replaceAll(',', ';');
      buffer.writeln('$ts,${e.packId},${e.type.name},$msg');
    }
    final csv = buffer.toString();
    try {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        await FileSaverService.instance.saveCsv('autogen_recent_errors', csv);
      } else {
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'autogen_recent_errors.csv'));
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(file.path)]);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recent errors exported')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export errors: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AutogenPackErrorEntry>>(
      valueListenable:
          AutogenPackErrorClassifierService.recentErrorsListenable(),
      builder: (context, errors, _) {
        final filtered = _filter == null
            ? errors
            : errors.where((e) => e.type == _filter).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Recent Errors',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    DropdownButton<AutogenPackErrorType?>(
                      value: _filter,
                      hint: const Text('Filter'),
                      onChanged: (v) => setState(() => _filter = v),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...AutogenPackErrorType.values.map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Export to CSV',
                      icon: const Icon(Icons.download),
                      onPressed: filtered.isEmpty
                          ? null
                          : () => _exportCsv(filtered),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Text('No recent errors')
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final e =
                            filtered[filtered.length -
                                1 -
                                index]; // latest first
                        final ts = DateFormat('HH:mm:ss').format(e.timestamp);
                        return ListTile(
                          dense: true,
                          leading: Text(ts),
                          title: Text(e.packId),
                          subtitle: Text(e.message),
                          trailing: Text(e.type.name),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
