import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'training_stats_service.dart';
import 'cloud_sync_service.dart';
import '../app_bootstrap.dart';

class SessionNoteService extends ChangeNotifier {
  static const _prefsKey = 'session_notes';
  static const _timeKey = 'session_notes_updated';

  SessionNoteService({this.cloud});

  final CloudSyncService? cloud;

  final Map<int, String> _notes = {};
  Map<int, String> get notes => _notes;

  String noteFor(int sessionId) => _notes[sessionId] ?? '';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(raw);
        _notes
          ..clear()
          ..addEntries(
            data.entries.map(
              (e) => MapEntry(int.parse(e.key), e.value as String),
            ),
          );
      } catch (_) {
        _notes.clear();
      }
    }
    if (cloud != null) {
      final remote = cloud!.getCached('session_notes');
      if (remote != null) {
        final remoteAt =
            DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final localAt = DateTime.tryParse(prefs.getString(_timeKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          final map = remote['notes'];
          if (map is Map) {
            _notes
              ..clear()
              ..addEntries(
                map.entries.map(
                  (e) => MapEntry(int.parse(e.key), e.value as String),
                ),
              );
            await _persist();
          }
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadSessionNotes(_notes);
        }
      }
    }
    notifyListeners();
  }

  Future<void> setNote(int sessionId, String note) async {
    _notes[sessionId] = note;
    await _persist();
    notifyListeners();
    if (cloud != null) {
      try {
        await cloud!.uploadSessionNotes(_notes);
      } catch (_) {
        AppBootstrap.sync?.cloud.syncUp();
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {for (final e in _notes.entries) e.key.toString(): e.value};
    await prefs.setString(_prefsKey, jsonEncode(data));
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
  }

  Future<String?> exportAsPdf(TrainingStatsService stats) async {
    if (_notes.values.every((n) => n.trim().isEmpty)) return null;
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();
    final pdf = pw.Document();
    final entries = _notes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Session Notes',
              style: pw.TextStyle(font: boldFont, fontSize: 24),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Sessions: ${stats.sessionsCompleted}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              'Hands: ${stats.handsReviewed}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              'Mistakes: ${stats.mistakesFixed}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              'Accuracy: ${(stats.evalAccuracy * 100).toStringAsFixed(1)}%',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.SizedBox(height: 12),
            for (final e in entries)
              if (e.value.trim().isNotEmpty) ...[
                pw.Text(
                  'Session ${e.key}',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.Text(e.value.trim(), style: pw.TextStyle(font: regularFont)),
                pw.SizedBox(height: 8),
              ],
          ];
        },
      ),
    );
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_notes.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await _shareFile(file);
    return file.path;
  }

  Future<void> _shareFile(File file) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.storage.request();
    }
    await Share.shareXFiles([XFile(file.path)]);
  }
}
