import 'package:flutter/material.dart';
import '../services/training_history_service_v2.dart';
import '../services/training_pack_library_loader_service.dart';

class BoosterArchiveScreen extends StatefulWidget {
  const BoosterArchiveScreen({super.key});

  @override
  State<BoosterArchiveScreen> createState() => _BoosterArchiveScreenState();
}

class _Entry {
  final String name;
  final DateTime date;
  final List<String> tags;
  final String? origin;

  _Entry({
    required this.name,
    required this.date,
    required this.tags,
    this.origin,
  });
}

enum _SortMode { recent, mostUsed, tag }

class _BoosterArchiveScreenState extends State<BoosterArchiveScreen> {
  bool _loading = true;
  final List<_Entry> _entries = [];
  String _tagFilter = '';
  String _originFilter = '';
  DateTimeRange? _dateRange;
  _SortMode _sort = _SortMode.recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await TrainingPackLibraryLoaderService.instance.preloadLibrary();
    final history = await TrainingHistoryServiceV2.getHistory(limit: 1000);
    final List<_Entry> list = [];
    for (final h in history) {
      final pack = TrainingPackLibraryLoaderService.instance.findById(h.packId);
      if (pack == null) continue;
      if (pack.meta['type']?.toString() != 'booster') continue;
      list.add(
        _Entry(
          name: pack.name,
          date: h.timestamp,
          tags: List<String>.from(h.tags),
          origin: pack.meta['origin']?.toString(),
        ),
      );
    }
    setState(() {
      _entries
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  List<String> get _allTags {
    final set = <String>{};
    for (final e in _entries) {
      set.addAll(e.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get _origins {
    final set = <String>{};
    for (final e in _entries) {
      if (e.origin != null) set.add(e.origin!);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<_Entry> get _filtered {
    final list = _entries.where((e) {
      final tagOk = _tagFilter.isEmpty || e.tags.contains(_tagFilter);
      final originOk = _originFilter.isEmpty || e.origin == _originFilter;
      final dateOk =
          _dateRange == null ||
          (!e.date.isBefore(_dateRange!.start) &&
              !e.date.isAfter(_dateRange!.end));
      return tagOk && originOk && dateOk;
    }).toList();

    switch (_sort) {
      case _SortMode.recent:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortMode.tag:
        list.sort(
          (a, b) => (a.tags.isEmpty ? '' : a.tags.first).compareTo(
            b.tags.isEmpty ? '' : b.tags.first,
          ),
        );
        break;
      case _SortMode.mostUsed:
        final counts = <String, int>{};
        for (final e in _entries) {
          counts.update(e.name, (v) => v + 1, ifAbsent: () => 1);
        }
        list.sort((a, b) {
          final ca = counts[a.name] ?? 0;
          final cb = counts[b.name] ?? 0;
          return cb.compareTo(ca);
        });
        break;
    }
    return list;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _dateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booster Archive')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: _tagFilter.isEmpty ? '' : _tagFilter,
                        hint: const Text('Tag'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All')),
                          for (final t in _allTags)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) => setState(() => _tagFilter = v ?? ''),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _originFilter.isEmpty ? '' : _originFilter,
                        hint: const Text('Origin'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All')),
                          for (final o in _origins)
                            DropdownMenuItem(value: o, child: Text(o)),
                        ],
                        onChanged: (v) =>
                            setState(() => _originFilter = v ?? ''),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _pickDateRange,
                            child: Text(
                              _dateRange == null
                                  ? 'Any Date'
                                  : '${_dateRange!.start.year}-${_dateRange!.start.month}-${_dateRange!.start.day} '
                                        'to ${_dateRange!.end.year}-${_dateRange!.end.month}-${_dateRange!.end.day}',
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<_SortMode>(
                            value: _sort,
                            items: const [
                              DropdownMenuItem(
                                value: _SortMode.recent,
                                child: Text('Recent'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.mostUsed,
                                child: Text('Most Used'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.tag,
                                child: Text('Tag'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _sort = v!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = _filtered[index];
                      return ListTile(
                        title: Text(e.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                            ),
                            if (e.tags.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: [
                                  for (final t in e.tags) Chip(label: Text(t)),
                                ],
                              ),
                            if (e.origin != null)
                              Text(
                                'Origin: ${e.origin!}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
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
