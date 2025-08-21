import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../widgets/saved_hand_tile.dart';
import '../widgets/sync_status_widget.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/mistake_streak_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';

class MistakeRepeatScreen extends StatefulWidget {
  const MistakeRepeatScreen({super.key});

  @override
  State<MistakeRepeatScreen> createState() => _MistakeRepeatScreenState();
}

class _MistakeRepeatScreenState extends State<MistakeRepeatScreen> {
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    final progress = context.read<MistakeReviewPackService>().progress;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MistakeStreakService>().update(progress),
    );
  }

  Map<String, List<SavedHand>> _groupMistakes(List<SavedHand> hands) {
    final mistakes = [
      for (final h in hands)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h,
    ]..sort((a, b) {
        final av = a.evLoss;
        final bv = b.evLoss;
        if (av == null && bv == null) return 0;
        if (av == null) return 1;
        if (bv == null) return -1;
        return bv.compareTo(av);
      });

    final Map<String, List<SavedHand>> grouped = {};
    for (final h in mistakes) {
      for (final tag in h.tags) {
        grouped.putIfAbsent(tag, () => []).add(h);
      }
    }
    return grouped;
  }

  Future<void> _exportPdf(BuildContext context) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final entries = _groupMistakes(hands)
        .entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text(
              'Повторы ошибок',
              style: pw.TextStyle(font: boldFont, fontSize: 24),
            ),
            pw.SizedBox(height: 16),
            for (final e in entries) ...[
              pw.Text(
                '${e.key} - ${e.value.length}',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 4),
              for (final h in e.value)
                pw.Bullet(
                  text: h.name,
                  style: pw.TextStyle(font: regularFont),
                ),
              pw.SizedBox(height: 12),
            ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final fileName =
        'mistake_repeats_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final entries = _groupMistakes(hands)
        .entries
        .where((e) => e.value.length > 1)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) return;

    final buffer = StringBuffer()
      ..writeln('# Повторы ошибок')
      ..writeln();
    for (final e in entries) {
      buffer.writeln('## ${e.key} (${e.value.length})');
      for (final h in e.value) {
        buffer.writeln('- ${h.name}');
      }
      buffer.writeln();
    }

    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final fileName =
        'mistake_repeats_${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    }
  }

  Future<void> _showExportOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Markdown'),
              onTap: () => Navigator.pop(ctx, 'md'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == 'md') {
      await _exportMarkdown(context);
    } else if (result == 'pdf') {
      await _exportPdf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final categories = {
      for (final h in hands)
        if (h.category != null && h.category!.isNotEmpty) h.category!,
    };
    final lossMap = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final loss = h.evLoss;
      if (cat != null && cat.isNotEmpty && loss != null) {
        lossMap[cat] = (lossMap[cat] ?? 0) + loss;
      }
    }
    final topLoss = lossMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final topThree = topLoss.take(3).toList();
    final filtered = [
      for (final h in hands)
        if (_categoryFilter == 'All' || h.category == _categoryFilter) h,
    ];
    final grouped = _groupMistakes(filtered);
    final streak = context.watch<MistakeStreakService>().count;

    final entries = grouped.entries.where((e) => e.value.length > 1).toList()
      ..sort((a, b) {
        final av = a.value.first.evLoss;
        final bv = b.value.first.evLoss;
        if (av == null && bv == null) {
          return b.value.length.compareTo(a.value.length);
        }
        if (av == null) return 1;
        if (bv == null) return -1;
        final cmp = bv.compareTo(av);
        return cmp != 0 ? cmp : b.value.length.compareTo(a.value.length);
      });

    final list = entries.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                SizedBox(height: 8),
                Text(
                  'Пока нет повторяющихся ошибок - так держать!',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(12),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    textColor: Colors.white,
                    collapsedTextColor: Colors.white,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${entry.value.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    children: [
                      for (final hand in entry.value)
                        SavedHandTile(
                          hand: hand,
                          onTap: () {
                            showSavedHandViewerDialog(context, hand);
                          },
                          onFavoriteToggle: () {
                            final manager =
                                context.read<SavedHandManagerService>();
                            final idx = manager.hands.indexOf(hand);
                            manager.update(
                              idx,
                              hand.copyWith(isFavorite: !hand.isFavorite),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );

    final body = Column(
      children: [
        if (streak > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Streak: $streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (topThree.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < topThree.length; i++) ...[
                  Text(
                    '${['🥇', '🥈', '🥉'][i]} ${topThree[i].key}: '
                    '${topThree[i].value >= 0 ? '+' : ''}${topThree[i].value.toStringAsFixed(2)} EV',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.amberAccent,
                    ),
                  ),
                  if (i < topThree.length - 1) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _categoryFilter,
              dropdownColor: const Color(0xFF2A2B2E),
              onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
              items: [
                'All',
                ...categories,
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),
          ),
        if (_categoryFilter != 'All' &&
            filtered.any(
              (h) =>
                  h.expectedAction != null &&
                  h.gtoAction != null &&
                  h.expectedAction!.trim().toLowerCase() !=
                      h.gtoAction!.trim().toLowerCase(),
            ))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final tpl = await TrainingPackService.createDrillFromCategory(
                  context,
                  _categoryFilter,
                );
                if (tpl == null) return;
                await context.read<TrainingSessionService>().startSession(tpl);
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Тренироваться на этой категории'),
            ),
          ),
        Expanded(child: list),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Повторы ошибок'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Экспорт',
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: body,
    );
  }
}
