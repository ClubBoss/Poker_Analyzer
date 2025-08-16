import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/spot_importer.dart';
import '../ui/session_player/mini_toast.dart';
import '../ui/session_player/mvs_player.dart';
import '../ui/session_player/models.dart';

class EmptyTrainingScreen extends StatelessWidget {
  const EmptyTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Нет доступных паков для тренировки'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _startBaseCourse(context),
              child: const Text('Start Base Course'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startBaseCourse(BuildContext context) async {
    List<UiSpot> spots = [];
    try {
      final f = File('out/seed_spots.json');
      if (f.existsSync()) {
        final content = await f.readAsString();
        final report = SpotImporter.parse(content, kind: 'json');
        spots = report.spots;
      }
    } catch (_) {}
    if (spots.isEmpty) {
      try {
        final result = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ['csv', 'json']);
        if (result == null || result.files.isEmpty) {
          showMiniToast(context, 'Import cancelled');
          return;
        }
        final f = result.files.first;
        String? content;
        if (f.path != null) {
          content = await File(f.path!).readAsString();
        } else if (f.bytes != null) {
          content = utf8.decode(f.bytes!);
        }
        if (content == null) {
          showMiniToast(context, 'Import failed');
          return;
        }
        final ext = (f.extension ?? '').toLowerCase();
        final report = SpotImporter.parse(content, kind: ext);
        spots = report.spots;
        for (final e in report.errors) {
          showMiniToast(context, e);
        }
        if (spots.isEmpty) {
          showMiniToast(context, 'No spots');
          return;
        }
      } catch (_) {
        showMiniToast(context, 'Import failed');
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MvsSessionPlayer(spots: spots, packId: 'seed:base'),
      ),
    );
  }
}
