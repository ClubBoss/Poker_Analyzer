import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../helpers/date_utils.dart';

import '../models/saved_hand.dart';
import 'saved_hand_storage_service.dart';
import 'cloud_sync_service.dart';
import "training_stats_service.dart";

class SavedHandManagerService extends ChangeNotifier {
  SavedHandManagerService({
    required SavedHandStorageService storage,
    CloudSyncService? cloud,
    TrainingStatsService? stats,
  })  : _storage = storage,
        _cloud = cloud,
        _stats = stats;

  final SavedHandStorageService _storage;
  final TrainingStatsService? _stats;
  final CloudSyncService? _cloud;

  List<SavedHand> get hands => _storage.hands;

  Set<String> tagFilters = {};

  Set<String> get allTags => hands.expand((h) => h.tags).toSet();

  Future<void> add(SavedHand hand) async {
    int sessionId = 1;
    final last = lastHand;
    if (last != null) {
      final diff = hand.savedAt.difference(last.savedAt).inMinutes;
      sessionId = diff > 60 ? last.sessionId + 1 : last.sessionId;
    }
    final withSession = hand.copyWith(sessionId: sessionId);
    await _storage.add(withSession);
    if (_cloud != null) {
      unawaited(_cloud.syncUp());
    }
    _stats?.incrementHands();
    if (sessionId != last?.sessionId) {
      _stats?.incrementSessions();
    }
  }

  Future<void> update(int index, SavedHand hand) async {
    final old = _storage.hands[index];
    await _storage.update(index, hand);
    final oldExp = old.expectedAction?.trim().toLowerCase();
    final oldGto = old.gtoAction?.trim().toLowerCase();
    final newExp = hand.expectedAction?.trim().toLowerCase();
    final newGto = hand.gtoAction?.trim().toLowerCase();
    if (oldExp != oldGto && newExp == newGto && newExp != null) {
      _stats?.incrementMistakes();
    }
  }

  Future<void> removeAt(int index) async {
    await _storage.removeAt(index);
  }

  /// Remove all hands belonging to the given session id and return them in
  /// chronological order. Useful for implementing session deletion with undo.
  Future<List<SavedHand>> removeSession(int sessionId) async {
    final removed = <SavedHand>[];
    for (int i = _storage.hands.length - 1; i >= 0; i--) {
      final hand = _storage.hands[i];
      if (hand.sessionId == sessionId) {
        removed.add(hand);
        await _storage.removeAt(i);
      }
    }
    notifyListeners();
    return removed.reversed.toList();
  }

  /// Restore previously removed session hands.
  Future<void> restoreSession(List<SavedHand> hands) async {
    for (final hand in hands) {
      await _storage.add(hand);
    }
    notifyListeners();
  }

  SavedHand? get lastHand => hands.isNotEmpty ? hands.last : null;

  /// Export all saved hands to a Markdown file located in the
  /// application documents directory. Returns the file path or `null`
  /// if there are no saved hands.
  Future<String?> exportAllHandsMarkdown() async {
    if (hands.isEmpty) return null;
    final buffer = StringBuffer();
    for (final hand in hands) {
      final title = hand.name.isNotEmpty ? hand.name : 'Без названия';
      buffer.writeln('## $title');
      final userAction = hand.expectedAction;
      if (userAction != null && userAction.isNotEmpty) {
        buffer.writeln('- Действие: $userAction');
      }
      if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
        buffer.writeln('- GTO: ${hand.gtoAction}');
      }
      if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty) {
        buffer.writeln('- Группа: ${hand.rangeGroup}');
      }
      if (hand.comment != null && hand.comment!.isNotEmpty) {
        buffer.writeln('- Комментарий: ${hand.comment}');
      }
      buffer.writeln();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/all_saved_hands.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Export all saved hands to a PDF file located in the
  /// application documents directory. Returns the file path or `null`
  /// if there are no saved hands.
  Future<String?> exportAllHandsPdf() async {
    if (hands.isEmpty) return null;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            for (final hand in hands) ...[
              pw.Text(
                hand.name.isNotEmpty ? hand.name : 'Без названия',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 8),
              if (hand.expectedAction != null &&
                  hand.expectedAction!.isNotEmpty)
                pw.Text('Действие: ${hand.expectedAction}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty)
                pw.Text('GTO: ${hand.gtoAction}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty)
                pw.Text('Группа: ${hand.rangeGroup}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.comment != null && hand.comment!.isNotEmpty)
                pw.Text('Комментарий: ${hand.comment}',
                    style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 12),
            ]
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/all_saved_hands.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Export statistics for all training sessions to a Markdown file named
  /// `training_summary.md` located in the application documents directory.
  /// [notes] should contain optional session notes keyed by session id.
  Future<String?> exportAllSessionsMarkdown(Map<int, String> notes) async {
    if (hands.isEmpty) return null;

    String _durToStr(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final parts = <String>[];
      if (h > 0) parts.add('${h}ч');
      parts.add('${m}м');
      return parts.join(' ');
    }

    final grouped = handsBySession().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer();

    for (final entry in grouped) {
      final id = entry.key;
      final sessionHands = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (sessionHands.isEmpty) continue;

      final start = sessionHands.first.savedAt;
      final end = sessionHands.last.savedAt;
      final duration = end.difference(start);
      int correct = 0;
      int incorrect = 0;
      for (final h in sessionHands) {
        final expected = h.expectedAction;
        final gto = h.gtoAction;
        if (expected != null && gto != null) {
          if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
            correct++;
          } else {
            incorrect++;
          }
        }
      }
      final total = correct + incorrect;
      final winrate = total > 0 ? (correct / total * 100) : null;
      final note = notes[id];

      buffer.writeln('## Сессия $id');
      buffer.writeln('- Дата: ${formatDateTime(end)}');
      buffer.writeln('- Длительность: ${_durToStr(duration)}');
      buffer.writeln('- Раздач: ${sessionHands.length}');
      buffer.writeln('- Верно: $correct');
      buffer.writeln('- Ошибки: $incorrect');
      if (winrate != null) {
        buffer.writeln('- Winrate: ${winrate.toStringAsFixed(1)}%');
      }
      if (note != null && note.trim().isNotEmpty) {
        buffer.writeln('- Заметка: ${note.trim()}');
      }
      buffer.writeln();
      for (final hand in sessionHands) {
        final title = hand.name.isNotEmpty ? hand.name : 'Без названия';
        buffer.writeln('### $title');
        final userAction = hand.expectedAction;
        if (userAction != null && userAction.isNotEmpty) {
          buffer.writeln('- Действие: $userAction');
        }
        if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
          buffer.writeln('- GTO: ${hand.gtoAction}');
        }
        if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty) {
          buffer.writeln('- Группа: ${hand.rangeGroup}');
        }
        if (hand.comment != null && hand.comment!.isNotEmpty) {
          buffer.writeln('- Комментарий: ${hand.comment}');
        }
        buffer.writeln();
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Export statistics for all training sessions to a PDF file named
  /// `training_summary.pdf` located in the application documents directory.
  /// [notes] should contain optional session notes keyed by session id.
  Future<String?> exportAllSessionsPdf(Map<int, String> notes) async {
    if (hands.isEmpty) return null;

    String _durToStr(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final parts = <String>[];
      if (h > 0) parts.add('${h}ч');
      parts.add('${m}м');
      return parts.join(' ');
    }

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final grouped = handsBySession().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            for (final entry in grouped) ...[
              () {
                final id = entry.key;
                final sessionHands = List<SavedHand>.from(entry.value)
                  ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
                final start = sessionHands.first.savedAt;
                final end = sessionHands.last.savedAt;
                final duration = end.difference(start);
                int correct = 0;
                int incorrect = 0;
                for (final h in sessionHands) {
                  final expected = h.expectedAction;
                  final gto = h.gtoAction;
                  if (expected != null && gto != null) {
                    if (expected.trim().toLowerCase() ==
                        gto.trim().toLowerCase()) {
                      correct++;
                    } else {
                      incorrect++;
                    }
                  }
                }
                final total = correct + incorrect;
                final winrate =
                    total > 0 ? (correct / total * 100).toStringAsFixed(1) : null;
                final note = notes[id];

                return [
                  pw.Text('Сессия $id',
                      style: pw.TextStyle(font: boldFont, fontSize: 20)),
                  pw.SizedBox(height: 4),
                  pw.Text('Дата: ${formatDateTime(end)}',
                      style: pw.TextStyle(font: regularFont)),
                  pw.Text('Длительность: ${_durToStr(duration)}',
                      style: pw.TextStyle(font: regularFont)),
                  pw.Text('Раздач: ${sessionHands.length} • Верно: $correct • Ошибки: $incorrect',
                      style: pw.TextStyle(font: regularFont)),
                  if (winrate != null)
                    pw.Text('Winrate: $winrate%',
                        style: pw.TextStyle(font: regularFont)),
                  if (note != null && note.trim().isNotEmpty)
                    pw.Text('Заметка: ${note.trim()}',
                        style: pw.TextStyle(font: regularFont)),
                  pw.SizedBox(height: 8),
                  for (final hand in sessionHands) ...[
                    pw.Text(
                      hand.name.isNotEmpty ? hand.name : 'Без названия',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 4),
                    if (hand.expectedAction != null &&
                        hand.expectedAction!.isNotEmpty)
                      pw.Text('Действие: ${hand.expectedAction}',
                          style: pw.TextStyle(font: regularFont)),
                    if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty)
                      pw.Text('GTO: ${hand.gtoAction}',
                          style: pw.TextStyle(font: regularFont)),
                    if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty)
                      pw.Text('Группа: ${hand.rangeGroup}',
                          style: pw.TextStyle(font: regularFont)),
                    if (hand.comment != null && hand.comment!.isNotEmpty)
                      pw.Text('Комментарий: ${hand.comment}',
                          style: pw.TextStyle(font: regularFont)),
                    pw.SizedBox(height: 12),
                  ],
                  pw.Divider(),
                ];
              }(),
            ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Export statistics for the specified training [sessionIds] to a Markdown
  /// file named `training_summary_filtered.md` located in the application
  /// documents directory. [notes] should contain optional session notes keyed
  /// by session id.
  Future<String?> exportSessionsMarkdown(
      List<int> sessionIds, Map<int, String> notes) async {
    if (sessionIds.isEmpty) return null;

    String _durToStr(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final parts = <String>[];
      if (h > 0) parts.add('${h}ч');
      parts.add('${m}м');
      return parts.join(' ');
    }

    final grouped = handsBySession();
    final ids = List<int>.from(sessionIds)..sort();
    final buffer = StringBuffer();

    for (final id in ids) {
      final sessionHands = grouped[id];
      if (sessionHands == null || sessionHands.isEmpty) continue;
      final handsList = List<SavedHand>.from(sessionHands)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      final start = handsList.first.savedAt;
      final end = handsList.last.savedAt;
      final duration = end.difference(start);
      int correct = 0;
      int incorrect = 0;
      for (final h in handsList) {
        final expected = h.expectedAction;
        final gto = h.gtoAction;
        if (expected != null && gto != null) {
          if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
            correct++;
          } else {
            incorrect++;
          }
        }
      }
      final total = correct + incorrect;
      final winrate = total > 0 ? (correct / total * 100) : null;
      final note = notes[id];

      buffer.writeln('## Сессия $id');
      buffer.writeln('- Дата: ${formatDateTime(end)}');
      buffer.writeln('- Длительность: ${_durToStr(duration)}');
      buffer.writeln('- Раздач: ${handsList.length}');
      buffer.writeln('- Верно: $correct');
      buffer.writeln('- Ошибки: $incorrect');
      if (winrate != null) {
        buffer.writeln('- Winrate: ${winrate.toStringAsFixed(1)}%');
      }
      if (note != null && note.trim().isNotEmpty) {
        buffer.writeln('- Заметка: ${note.trim()}');
      }
      buffer.writeln();
      for (final hand in handsList) {
        final title = hand.name.isNotEmpty ? hand.name : 'Без названия';
        buffer.writeln('### $title');
        final userAction = hand.expectedAction;
        if (userAction != null && userAction.isNotEmpty) {
          buffer.writeln('- Действие: $userAction');
        }
        if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
          buffer.writeln('- GTO: ${hand.gtoAction}');
        }
        if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty) {
          buffer.writeln('- Группа: ${hand.rangeGroup}');
        }
        if (hand.comment != null && hand.comment!.isNotEmpty) {
          buffer.writeln('- Комментарий: ${hand.comment}');
        }
        buffer.writeln();
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary_filtered.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Export statistics for the specified training [sessionIds] to a PDF file
  /// named `training_summary_filtered.pdf` located in the application documents
  /// directory. [notes] should contain optional session notes keyed by session
  /// id.
  Future<String?> exportSessionsPdf(
      List<int> sessionIds, Map<int, String> notes) async {
    if (sessionIds.isEmpty) return null;

    String _durToStr(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final parts = <String>[];
      if (h > 0) parts.add('${h}ч');
      parts.add('${m}м');
      return parts.join(' ');
    }

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final grouped = handsBySession();
    final ids = List<int>.from(sessionIds)..sort();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            for (final id in ids)
              if (grouped[id] != null && grouped[id]!.isNotEmpty) ...[
                () {
                  final handsList = List<SavedHand>.from(grouped[id]!)
                    ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
                  final start = handsList.first.savedAt;
                  final end = handsList.last.savedAt;
                  final duration = end.difference(start);
                  int correct = 0;
                  int incorrect = 0;
                  for (final h in handsList) {
                    final expected = h.expectedAction;
                    final gto = h.gtoAction;
                    if (expected != null && gto != null) {
                      if (expected.trim().toLowerCase() ==
                          gto.trim().toLowerCase()) {
                        correct++;
                      } else {
                        incorrect++;
                      }
                    }
                  }
                  final total = correct + incorrect;
                  final winrate =
                      total > 0 ? (correct / total * 100).toStringAsFixed(1) : null;
                  final note = notes[id];

                  return [
                    pw.Text('Сессия $id',
                        style: pw.TextStyle(font: boldFont, fontSize: 20)),
                    pw.SizedBox(height: 4),
                    pw.Text('Дата: ${formatDateTime(end)}',
                        style: pw.TextStyle(font: regularFont)),
                    pw.Text('Длительность: ${_durToStr(duration)}',
                        style: pw.TextStyle(font: regularFont)),
                    pw.Text('Раздач: ${handsList.length} • Верно: $correct • Ошибки: $incorrect',
                        style: pw.TextStyle(font: regularFont)),
                    if (winrate != null)
                      pw.Text('Winrate: $winrate%',
                          style: pw.TextStyle(font: regularFont)),
                    if (note != null && note.trim().isNotEmpty)
                      pw.Text('Заметка: ${note.trim()}',
                          style: pw.TextStyle(font: regularFont)),
                    pw.SizedBox(height: 8),
                    for (final hand in handsList) ...[
                      pw.Text(
                        hand.name.isNotEmpty ? hand.name : 'Без названия',
                        style: pw.TextStyle(font: boldFont, fontSize: 16),
                      ),
                      pw.SizedBox(height: 4),
                      if (hand.expectedAction != null && hand.expectedAction!.isNotEmpty)
                        pw.Text('Действие: ${hand.expectedAction}',
                            style: pw.TextStyle(font: regularFont)),
                      if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty)
                        pw.Text('GTO: ${hand.gtoAction}',
                            style: pw.TextStyle(font: regularFont)),
                      if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty)
                        pw.Text('Группа: ${hand.rangeGroup}',
                            style: pw.TextStyle(font: regularFont)),
                      if (hand.comment != null && hand.comment!.isNotEmpty)
                        pw.Text('Комментарий: ${hand.comment}',
                            style: pw.TextStyle(font: regularFont)),
                      pw.SizedBox(height: 12),
                    ],
                    pw.Divider(),
                  ];
                }(),
              ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_summary_filtered.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Export hands belonging to [sessionId] to a Markdown file. The file
  /// will be named `session_[id].md` and stored in the application documents
  /// directory. Returns the created path or `null` if the session is empty.
  Future<String?> exportSessionHandsMarkdown(int sessionId, {String? note}) async {
    final sessionHands =
        hands.where((h) => h.sessionId == sessionId).toList();
    if (sessionHands.isEmpty) return null;
    final buffer = StringBuffer();
    if (note != null && note.trim().isNotEmpty) {
      buffer.writeln(note.trim());
      buffer.writeln();
    }
    for (final hand in sessionHands) {
      final title = hand.name.isNotEmpty ? hand.name : 'Без названия';
      buffer.writeln('## $title');
      final userAction = hand.expectedAction;
      if (userAction != null && userAction.isNotEmpty) {
        buffer.writeln('- Действие: $userAction');
      }
      if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty) {
        buffer.writeln('- GTO: ${hand.gtoAction}');
      }
      if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty) {
        buffer.writeln('- Группа: ${hand.rangeGroup}');
      }
      if (hand.comment != null && hand.comment!.isNotEmpty) {
        buffer.writeln('- Комментарий: ${hand.comment}');
      }
      buffer.writeln();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_${sessionId}.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Export hands belonging to [sessionId] to a PDF file. The file will be
  /// named `session_[id].pdf` and stored in the application documents
  /// directory. Returns the created path or `null` if the session is empty.
  Future<String?> exportSessionHandsPdf(int sessionId, {String? note}) async {
    final sessionHands =
        hands.where((h) => h.sessionId == sessionId).toList();
    if (sessionHands.isEmpty) return null;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            if (note != null && note.trim().isNotEmpty) ...[
              pw.Text(note.trim(), style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 12),
            ],
            for (final hand in sessionHands) ...[
              pw.Text(
                hand.name.isNotEmpty ? hand.name : 'Без названия',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 8),
              if (hand.expectedAction != null &&
                  hand.expectedAction!.isNotEmpty)
                pw.Text('Действие: ${hand.expectedAction}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.gtoAction != null && hand.gtoAction!.isNotEmpty)
                pw.Text('GTO: ${hand.gtoAction}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.rangeGroup != null && hand.rangeGroup!.isNotEmpty)
                pw.Text('Группа: ${hand.rangeGroup}',
                    style: pw.TextStyle(font: regularFont)),
              if (hand.comment != null && hand.comment!.isNotEmpty)
                pw.Text('Комментарий: ${hand.comment}',
                    style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 12),
            ]
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_${sessionId}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Export all sessions to a ZIP archive with Markdown or PDF files grouped
  /// by session. Each session will be saved in a folder named by the session
  /// date. Returns the archive path or `null` if there are no hands.
  Future<String?> exportSessionsArchive({bool pdf = false}) async {
    if (hands.isEmpty) return null;

    String _folder(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    final archive = Archive();
    final grouped = handsBySession();
    for (final entry in grouped.entries) {
      final id = entry.key;
      final list = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (list.isEmpty) continue;
      final folder = _folder(list.first.savedAt);
      final path = pdf
          ? await exportSessionHandsPdf(id)
          : await exportSessionHandsMarkdown(id);
      if (path == null) continue;
      final file = File(path);
      final data = await file.readAsBytes();
      final ext = pdf ? 'pdf' : 'md';
      final name = '$folder/session_$id.$ext';
      archive.addFile(ArchiveFile(name, data.length, data));
      await file.delete();
    }

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final out =
        File('${dir.path}/saved_hands_archive_${DateTime.now().millisecondsSinceEpoch}.zip');
    await out.writeAsBytes(bytes);
    return out.path;
  }

  Future<SavedHand?> selectHand(BuildContext context) async {
    if (hands.isEmpty) return null;
    String filter = '';
    String dateFilter = 'Все';
    String sortOrder = 'По дате (новые сверху)';
    Set<String> localFilters = {...tagFilters};
    final selected = await showDialog<SavedHand>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool sameDay(DateTime a, DateTime b) {
            return a.year == b.year && a.month == b.month && a.day == b.day;
          }

          final query = filter.toLowerCase();
          final now = DateTime.now();
          final filtered = [
            for (final hand in hands)
              if ((query.isEmpty ||
                      hand.tags.any((t) => t.toLowerCase().contains(query)) ||
                      hand.name.toLowerCase().contains(query) ||
                      (hand.comment?.toLowerCase().contains(query) ?? false)) &&
                  (localFilters.isEmpty ||
                      localFilters.every((tag) => hand.tags.contains(tag))) &&
                  (dateFilter == 'Все' ||
                      (dateFilter == 'Сегодня' && sameDay(hand.savedAt, now)) ||
                      (dateFilter == 'Последние 7 дней' &&
                          hand.savedAt.isAfter(now.subtract(const Duration(days: 7)))))
                hand
          ];

          filtered.sort((a, b) => sortOrder == 'По дате (новые сверху)'
              ? b.savedAt.compareTo(a.savedAt)
              : a.savedAt.compareTo(b.savedAt));
          return AlertDialog(
            title: const Text('Выберите раздачу'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: 'Поиск'),
                    onChanged: (value) => setStateDialog(() => filter = value),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setStateSheet) {
                              final tags = allTags.toList()..sort();
                              if (tags.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Нет тегов'),
                                );
                              }
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  for (final tag in tags)
                                    CheckboxListTile(
                                      title: Text(tag),
                                      value: localFilters.contains(tag),
                                      onChanged: (checked) {
                                        setStateSheet(() {
                                          if (checked == true) {
                                            localFilters.add(tag);
                                          } else {
                                            localFilters.remove(tag);
                                          }
                                          tagFilters = Set.from(localFilters);
                                        });
                                        setStateDialog(() {});
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        );
                        setStateDialog(() {});
                      },
                    child: const Text('Фильтр по тегам'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: dateFilter,
                      dropdownColor: const Color(0xFF2A2B2E),
                      onChanged: (v) => setStateDialog(() => dateFilter = v ?? 'Все'),
                      items: const ['Все', 'Сегодня', 'Последние 7 дней']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: sortOrder,
                      dropdownColor: const Color(0xFF2A2B2E),
                      onChanged: (v) => setStateDialog(
                          () => sortOrder = v ?? 'По дате (новые сверху)'),
                      items: const [
                        'По дате (новые сверху)',
                        'По дате (старые сверху)'
                      ]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final hand = filtered[index];
                        final savedIndex = hands.indexOf(hand);
                        final title =
                            hand.name.isNotEmpty ? hand.name : 'Без названия';
                        return ListTile(
                          dense: true,
                          title: Text(
                            '$title \u2022 ${formatLongDate(hand.savedAt)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: () {
                            final items = <Widget>[];
                            if (hand.tags.isNotEmpty) {
                              items.add(Text(
                                hand.tags.join(', '),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ));
                            }
                            if (hand.comment?.isNotEmpty ?? false) {
                              items.add(Text(
                                hand.comment!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ));
                            }
                            return items.isEmpty
                                ? null
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: items,
                                  );
                          }(),
                          onTap: () => Navigator.pop(context, hand),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final nameController =
                                      TextEditingController(text: hand.name);
                                  final tagsController = TextEditingController(
                                      text: hand.tags.join(', '));
                                  final commentController =
                                      TextEditingController(text: hand.comment ?? '');

                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(context).viewInsets.bottom,
                                        left: 16,
                                        right: 16,
                                        top: 16,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            TextField(
                                              controller: nameController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Название'),
                                            ),
                                            const SizedBox(height: 8),
                                            Autocomplete<String>(
                                              optionsBuilder: (TextEditingValue value) {
                                                final input = value.text.toLowerCase();
                                                if (input.isEmpty) {
                                                  return const Iterable<String>.empty();
                                                }
                                                return allTags.where(
                                                    (tag) => tag.toLowerCase().contains(input));
                                              },
                                              displayStringForOption: (opt) => opt,
                                              onSelected: (selection) {
                                                final tags = tagsController.text
                                                    .split(',')
                                                    .map((t) => t.trim())
                                                    .where((t) => t.isNotEmpty)
                                                    .toSet();
                                                if (tags.add(selection)) {
                                                  tagsController.text = tags.join(', ');
                                                  tagsController.selection = TextSelection.fromPosition(
                                                      TextPosition(offset: tagsController.text.length));
                                                }
                                              },
                                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                                textEditingController.text = tagsController.text;
                                                textEditingController.selection = tagsController.selection;
                                                textEditingController.addListener(() {
                                                  if (tagsController.text != textEditingController.text) {
                                                    tagsController.value = textEditingController.value;
                                                  }
                                                });
                                                tagsController.addListener(() {
                                                  if (textEditingController.text != tagsController.text) {
                                                    textEditingController.value = tagsController.value;
                                                  }
                                                });
                                                return TextField(
                                                  controller: textEditingController,
                                                  focusNode: focusNode,
                                                  decoration: const InputDecoration(labelText: 'Теги'),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: commentController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Комментарий'),
                                              keyboardType: TextInputType.multiline,
                                              maxLines: null,
                                            ),
                                            const SizedBox(height: 16),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Отмена'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  final newName = nameController.text.trim();
                                  final newTags = tagsController.text
                                      .split(',')
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();
                                  final newComment = commentController.text.trim();

                                  final old = hands[savedIndex];
                                  final oldName = old.name.trim();
                                  final oldTags = old.tags
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();
                                  final oldComment = old.comment?.trim() ?? '';

                                  final hasChanges = newName != oldName ||
                                      !listEquals(newTags, oldTags) ||
                                      newComment != oldComment;

                                  if (hasChanges) {
                                    final updated = old.copyWith(
                                      name: newName,
                                      comment: newComment.isNotEmpty ? newComment : null,
                                      tags: newTags,
                                    );
                                    await _storage.update(savedIndex, updated);
                                    setStateSheet(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Раздача обновлена')),
                                    );
                                  }

                                  nameController.dispose();
                                  tagsController.dispose();
                                  commentController.dispose();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Удалить раздачу?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Удалить'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _storage.removeAt(savedIndex);
                                    setStateDialog(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected != null) {
      tagFilters = Set.from(localFilters);
    }
    return selected;
  }

  /// Group saved hands by their session identifier.
  Map<int, List<SavedHand>> handsBySession() {
    final Map<int, List<SavedHand>> grouped = {};
    for (final hand in hands) {
      grouped.putIfAbsent(hand.sessionId, () => []).add(hand);
    }
    return grouped;
  }

  /// Return the list of hands in the current error-free streak.
  ///
  /// Hands are returned in chronological order and only include
  /// those with correct user action compared to GTO.
  List<SavedHand> currentErrorFreeStreak() {
    final result = <SavedHand>[];
    for (int i = hands.length - 1; i >= 0; i--) {
      final h = hands[i];
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (expected == null || gto == null || expected != gto) {
        break;
      }
      result.insert(0, h);
    }
    return result;
  }

  /// Returns all completed error-free streaks of 5+ correct hands.
  ///
  /// Each streak is represented as a list of [SavedHand] objects in
  /// chronological order. Only sequences terminated by a mistake are
  /// included – the current ongoing streak (if any) is omitted.
  List<List<SavedHand>> completedErrorFreeStreaks() {
    final List<List<SavedHand>> streaks = [];
    final List<SavedHand> current = [];

    bool isCorrect(SavedHand h) {
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      return expected != null && gto != null && expected == gto;
    }

    for (final h in hands) {
      if (isCorrect(h)) {
        current.add(h);
      } else {
        if (current.length >= 5) {
          streaks.add(List<SavedHand>.from(current));
        }
        current.clear();
      }
    }

    // Only completed streaks are returned, so the trailing streak is ignored.
    return streaks.reversed.toList();
  }
}
