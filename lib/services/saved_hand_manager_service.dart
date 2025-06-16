import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import 'saved_hand_storage_service.dart';

class SavedHandManagerService extends ChangeNotifier {
  SavedHandManagerService({required SavedHandStorageService storage})
      : _storage = storage;

  final SavedHandStorageService _storage;

  List<SavedHand> get hands => _storage.hands;

  Set<String> tagFilters = {};

  Set<String> get allTags => hands.expand((h) => h.tags).toSet();

  Future<void> add(SavedHand hand) async {
    await _storage.add(hand);
  }

  Future<void> update(int index, SavedHand hand) async {
    await _storage.update(index, hand);
  }

  Future<void> removeAt(int index) async {
    await _storage.removeAt(index);
  }

  SavedHand? get lastHand => hands.isNotEmpty ? hands.last : null;

  Future<SavedHand?> selectHand(BuildContext context) async {
    if (hands.isEmpty) return null;
    String filter = '';
    Set<String> localFilters = {...tagFilters};
    final selected = await showDialog<SavedHand>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final query = filter.toLowerCase();
          final filtered = [
            for (final hand in hands)
              if ((query.isEmpty ||
                      hand.tags.any((t) => t.toLowerCase().contains(query)) ||
                      hand.name.toLowerCase().contains(query) ||
                      (hand.comment?.toLowerCase().contains(query) ?? false)) &&
                  (localFilters.isEmpty ||
                      localFilters.every((tag) => hand.tags.contains(tag))))
                hand
          ];
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
                            title,
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
}
