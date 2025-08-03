import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../helpers/date_utils.dart';

import '../models/saved_hand.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/training_pack.dart';
import 'saved_hand_storage_service.dart';
import 'cloud_sync_service.dart';

import 'training_stats_service.dart';

class SavedHandManagerService extends ChangeNotifier {
  static SavedHandManagerService? _instance;
  static SavedHandManagerService? get instance => _instance;

  SavedHandManagerService({
    required SavedHandStorageService storage,
    CloudSyncService? cloud,
    TrainingStatsService? stats,
  })  : _storage = storage,
        _cloud = cloud,
        _stats = stats {
    _instance = this;
  }

  final SavedHandStorageService _storage;
  final TrainingStatsService? _stats;
  final CloudSyncService? _cloud;

  Future<void> _sync() async {
    if (_cloud == null) return;
    await _cloud.queueMutation('saved_hands', 'main', {
      'hands': [for (final h in hands) h.toJson()],
      'updatedAt': DateTime.now().toIso8601String(),
    });
    unawaited(_cloud.syncUp());
  }

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
    await _sync();
    _stats?.incrementHands();
    final cat = withSession.category;
    final ev = withSession.heroEv;
    final exp = withSession.expectedAction?.trim().toLowerCase();
    final gto = withSession.gtoAction?.trim().toLowerCase();
    final miss = exp != null && gto != null && exp != gto;
    _stats?.updateSkill(cat, ev, miss);
    if (sessionId != last?.sessionId) {
      _stats?.incrementSessions();
    }
  }

  Future<void> addHands(List<SavedHand> hands) async {
    if (hands.isEmpty) return;
    final sorted = List<SavedHand>.from(hands)
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    for (final hand in sorted) {
      await add(hand);
    }
  }

  Future<void> update(int index, SavedHand hand) async {
    final old = _storage.hands[index];
    await _storage.update(index, hand);
    await _sync();
    final oldExp = old.expectedAction?.trim().toLowerCase();
    final oldGto = old.gtoAction?.trim().toLowerCase();
    final newExp = hand.expectedAction?.trim().toLowerCase();
    final newGto = hand.gtoAction?.trim().toLowerCase();
    if (oldExp != oldGto && newExp == newGto && newExp != null) {
      _stats?.incrementMistakes();
    }
  }

  Future<void> save(SavedHand hand) async {
    final index = hands.indexWhere((h) => h.savedAt == hand.savedAt);
    if (index >= 0) {
      await update(index, hand);
    } else {
      await add(hand);
    }
  }

  Future<void> removeAt(int index) async {
    await _storage.removeAt(index);
    await _sync();
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
    await _sync();
    notifyListeners();
    return removed.reversed.toList();
  }

  /// Restore previously removed session hands.
  Future<void> restoreSession(List<SavedHand> hands) async {
    for (final hand in hands) {
      await _storage.add(hand);
    }
    await _sync();
    notifyListeners();
  }

  SavedHand? get lastHand => hands.isNotEmpty ? hands.last : null;

  Future<SavedHand?> selectHand(BuildContext context) async {
    if (hands.isEmpty) return null;
    String filter = '';
    String dateFilter = 'Все';
    String sortOrder = 'По дате (новые сверху)';
    final Set<String> localFilters = {...tagFilters};
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


  TrainingPackTemplate createPack(String name, List<SavedHand> selected) {
    HeroPosition pos(String s) => parseHeroPosition(s);

    TrainingPackSpot spotFromHand(SavedHand h) {
      final cards =
          h.playerCards[h.heroIndex].map((c) => '${c.rank}${c.suit}').join(' ');
      final stacks = {
        for (int i = 0; i < h.numberOfPlayers; i++)
          '$i': (h.stackSizes[i] ?? 0).toDouble()
      };
      final acts = [for (final a in h.actions) if (a.street == 0) a];
      return TrainingPackSpot(
        id: const Uuid().v4(),
        hand: HandData(
          heroCards: cards,
          position: pos(h.heroPosition),
          heroIndex: h.heroIndex,
          playerCount: h.numberOfPlayers,
          stacks: stacks,
          actions: {0: acts},
          anteBb: h.anteBb,
        ),
        tags: List<String>.from(h.tags),
      );
    }

    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: name,
      gameType: parseGameType(selected.isNotEmpty ? selected.first.gameType : ''),
      spots: [for (final h in selected) spotFromHand(h)],
      tags: {for (final h in selected) ...h.tags}.toList(),
      createdAt: DateTime.now(),
    );
    return tpl;
  }
}
