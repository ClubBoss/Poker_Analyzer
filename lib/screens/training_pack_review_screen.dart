import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../widgets/replay_spot_widget.dart';
import '../theme/app_colors.dart';
import '../services/tag_service.dart';
import '../services/training_pack_storage_service.dart';

/// Displays all spots from [pack] with option to show only mistaken ones.
class TrainingPackReviewScreen extends StatefulWidget {
  final TrainingPack pack;
  final Set<String> mistakenNames;

  const TrainingPackReviewScreen({
    super.key,
    required this.pack,
    this.mistakenNames = const {},
  });

  @override
  State<TrainingPackReviewScreen> createState() => _TrainingPackReviewScreenState();
}

enum _SortOption { name, rating, date }

class _TrainingPackReviewScreenState extends State<TrainingPackReviewScreen> {
  static const _mistakesKey = 'review_show_mistakes';
  static const _sortKey = 'review_sort_option';
  static const _searchKey = 'review_search_query';

  SharedPreferences? _prefs;
  bool _onlyMistakes = false;
  final TextEditingController _searchController = TextEditingController();
  _SortOption _sort = _SortOption.name;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt(_sortKey) ?? 0;
    setState(() {
      _prefs = prefs;
      _onlyMistakes = prefs.getBool(_mistakesKey) ?? false;
      _sort = _SortOption.values[sortIndex.clamp(0, _SortOption.values.length - 1)];
      _searchController.text = prefs.getString(_searchKey) ?? '';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_mistakesKey, _onlyMistakes);
    await prefs.setInt(_sortKey, _sort.index);
    await prefs.setString(_searchKey, _searchController.text);
  }

  List<SavedHand> get _visibleHands {
    final List<SavedHand> list = [];
    if (!_onlyMistakes) {
      list.addAll(widget.pack.hands);
    } else {
      for (final h in widget.pack.hands) {
        if (widget.mistakenNames.contains(h.name)) list.add(h);
      }
    }
    switch (_sort) {
      case _SortOption.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.date:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
    }
    return list;
  }

  Future<void> _savePack() async {
    final service = context.read<TrainingPackStorageService>();
    await service.removePack(widget.pack);
    await service.addPack(widget.pack);
  }

  @override
  void dispose() {
    _savePrefs();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editHand(SavedHand hand) async {
    int rating = hand.rating;
    final Set<String> tags = {...hand.tags};
    final allTags = context.read<TagService>().tags;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(hand.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= 5; i++)
                        IconButton(
                          icon: Icon(
                            i <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setStateDialog(() => rating = i),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final tag in allTags)
                        FilterChip(
                          label: Text(tag),
                          selected: tags.contains(tag),
                          onSelected: (selected) => setStateDialog(() {
                            if (selected) {
                              tags.add(tag);
                            } else {
                              tags.remove(tag);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final updated = hand.copyWith(
                    rating: rating,
                    tags: tags.toList(),
                  );
                  final index = widget.pack.hands.indexOf(hand);
                  if (index != -1) {
                    widget.pack.hands[index] = updated;
                  }
                  _savePack();
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteHand(SavedHand hand) async {
    setState(() => widget.pack.hands.remove(hand));
    await _savePack();
  }

  Future<void> _confirmDeleteHand(SavedHand hand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hand?'),
        content:
            const Text('Are you sure you want to delete this hand?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _deleteHand(hand);
    }
  }

  Future<void> _showHandOptions(SavedHand hand) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(hand.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: const Text('Edit'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == 'edit') {
      await _editHand(hand);
    } else if (result == 'delete') {
      await _confirmDeleteHand(hand);
    }
  }

  String _generateMarkdown() {
    final buffer = StringBuffer('# ${widget.pack.name}\n\n');
    for (final hand in widget.pack.hands) {
      final mistake = widget.mistakenNames.contains(hand.name);
      final tags = hand.tags.join(', ');
      buffer.writeln('### ${hand.name}');
      buffer.writeln('- Rating: ${hand.rating}');
      if (tags.isNotEmpty) buffer.writeln('- Tags: $tags');
      buffer.writeln('- Mistake: ${mistake ? 'Yes' : 'No'}');
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  Future<void> _exportMarkdown() async {
    final markdown = _generateMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markdown copied to clipboard')),
      );
    }
  }

  Future<void> _exportPdf() async {
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text(widget.pack.name,
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            for (final hand in widget.pack.hands)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(hand.name,
                      style: pw.TextStyle(font: boldFont, fontSize: 18)),
                  pw.Bullet(
                      text: 'Rating: ${hand.rating}',
                      style: pw.TextStyle(font: regularFont)),
                  if (hand.tags.isNotEmpty)
                    pw.Bullet(
                        text: 'Tags: ${hand.tags.join(', ')}',
                        style: pw.TextStyle(font: regularFont)),
                  pw.Bullet(
                      text:
                          'Mistake: ${widget.mistakenNames.contains(hand.name) ? 'Yes' : 'No'}',
                      style: pw.TextStyle(font: regularFont)),
                  pw.SizedBox(height: 8),
                ],
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final safeName = widget.pack.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $fileName'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    }
  }

  Widget _buildHandTile(SavedHand hand) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(hand.name, style: const TextStyle(color: Colors.white)),
        subtitle: Wrap(
          spacing: 4,
          children: [for (final t in hand.tags) Chip(label: Text(t))],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 5; i++)
              Icon(
                i < hand.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) =>
                ReplaySpotWidget(spot: TrainingSpot.fromSavedHand(hand)),
          );
        },
        onLongPress: () => _showHandOptions(hand),
      ),
    );
  }

  Widget _buildPackOverview() {
    final history = widget.pack.history;
    final hasHistory = history.isNotEmpty;
    final hasRatings = widget.pack.hands.any((h) => h.rating > 0);
    if (!hasHistory && !hasRatings) return const SizedBox.shrink();
    final total = hasHistory
        ? history.fold<int>(0, (p, r) => p + r.total)
        : 0;
    final correct = hasHistory
        ? history.fold<int>(0, (p, r) => p + r.correct)
        : 0;
    final mistakes = total - correct;
    final accuracy = total > 0 ? correct * 100 / total : 0.0;
    final ratingAvg = widget.pack.hands.isNotEmpty
        ? widget.pack.hands
                .map((h) => h.rating)
                .reduce((a, b) => a + b) /
            widget.pack.hands.length
        : 0.0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠 Обзор пака',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text('Кол-во рук: $total',
              style: const TextStyle(color: Colors.white)),
          Text('Точность: ${accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white)),
          Text('Ошибок: $mistakes',
              style: const TextStyle(color: Colors.white)),
          Text('Средний рейтинг: ${ratingAvg.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleHands;
    final query = _searchController.text.toLowerCase();
    final hands = query.isEmpty
        ? visible
        : [
            for (final h in visible)
              if (h.name.toLowerCase().contains(query)) h
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export to Markdown',
            onPressed: _exportMarkdown,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Show mistakes only'),
            value: _onlyMistakes,
            onChanged: widget.mistakenNames.isEmpty
                ? null
                : (v) async {
                    setState(() => _onlyMistakes = v);
                    final prefs =
                        _prefs ?? await SharedPreferences.getInstance();
                    await prefs.setBool(_mistakesKey, v);
                  },
            activeColor: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search',
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () async {
                          _searchController.clear();
                          final prefs =
                              _prefs ?? await SharedPreferences.getInstance();
                          await prefs.setString(_searchKey, '');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) async {
                setState(() {});
                final prefs =
                    _prefs ?? await SharedPreferences.getInstance();
                await prefs.setString(_searchKey, _searchController.text);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Sort by',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<_SortOption>(
                  value: _sort,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                        value: _SortOption.name, child: Text('Name')),
                    DropdownMenuItem(
                        value: _SortOption.rating, child: Text('Rating')),
                    DropdownMenuItem(
                        value: _SortOption.date, child: Text('Date')),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _sort = value);
                    final prefs =
                        _prefs ?? await SharedPreferences.getInstance();
                    await prefs.setInt(_sortKey, value.index);
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildPackOverview(),
          Expanded(
            child: hands.isEmpty
                ? const Center(
                    child: Text(
                      'No spots',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: hands.length,
                    itemBuilder: (context, index) => _buildHandTile(hands[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

