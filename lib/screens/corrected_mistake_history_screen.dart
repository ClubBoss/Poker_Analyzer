import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import 'mistake_detail_screen.dart';
import '../helpers/category_translations.dart';

class CorrectedMistakeHistoryScreen extends StatefulWidget {
  final String? category;
  const CorrectedMistakeHistoryScreen({super.key, this.category});

  @override
  State<CorrectedMistakeHistoryScreen> createState() =>
      _CorrectedMistakeHistoryScreenState();
}

class _CorrectedMistakeHistoryScreenState
    extends State<CorrectedMistakeHistoryScreen> {
  bool _evOnly = false;

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final all = [
      for (final h in hands)
        if (h.corrected &&
            (widget.category == null || h.category == widget.category))
          h,
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final filtered = _evOnly
        ? [
            for (final h in all)
              if (h.evLossRecovered != null && h.evLossRecovered! > 0) h,
          ]
        : all;
    final title = widget.category == null
        ? 'Исправленные ошибки'
        : 'Исправленные ошибки: ${translateCategory(widget.category).isEmpty ? 'Без категории' : translateCategory(widget.category)}';
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: all.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                SwitchListTile(
                  value: _evOnly,
                  onChanged: (v) => setState(() => _evOnly = v),
                  title: const Text(
                    'Показать только с EV',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeColor: Colors.orange,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет данных',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final h = filtered[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MistakeDetailScreen(hand: h),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h.heroPosition,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (h.evLossRecovered != null)
                                            Text(
                                              '+${h.evLossRecovered!.toStringAsFixed(2)} EV',
                                              style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (h.tags.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Wrap(
                                                spacing: 4,
                                                children: [
                                                  for (final t in h.tags)
                                                    Chip(
                                                      label: Text(t),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF3A3B3E,
                                                          ),
                                                      labelStyle:
                                                          const TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
