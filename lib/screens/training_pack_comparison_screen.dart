import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../models/training_pack.dart';
import 'training_pack_review_screen.dart';

class TrainingPackComparisonScreen extends StatefulWidget {
  const TrainingPackComparisonScreen({super.key});

  @override
  State<TrainingPackComparisonScreen> createState() => _TrainingPackComparisonScreenState();
}

class _PackStats {
  final TrainingPack pack;
  final String name;
  final int total;
  final int mistakes;
  final double accuracy;
  final double rating;

  _PackStats({
    required this.pack,
    required this.name,
    required this.total,
    required this.mistakes,
    required this.accuracy,
    required this.rating,
  });

  factory _PackStats.fromPack(TrainingPack p) {
    final history = p.history;
    final total = history.fold<int>(0, (p0, r) => p0 + r.total);
    final correct = history.fold<int>(0, (p0, r) => p0 + r.correct);
    final mistakes = total - correct;
    final accuracy = total > 0 ? correct * 100 / total : 0.0;
    final ratingAvg = p.hands.isNotEmpty
        ? p.hands.map((h) => h.rating).reduce((a, b) => a + b) / p.hands.length
        : 0.0;
    return _PackStats(
      pack: p,
      name: p.name,
      total: total,
      mistakes: mistakes,
      accuracy: accuracy,
      rating: ratingAvg,
    );
  }
}

class _TrainingPackComparisonScreenState extends State<TrainingPackComparisonScreen> {
  int _sortColumn = 0;
  bool _ascending = true;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;
    final stats = [for (final p in packs) _PackStats.fromPack(p)]..sort((a, b) {
        int cmp;
        switch (_sortColumn) {
          case 0:
            cmp = a.name.compareTo(b.name);
            break;
          case 1:
            cmp = a.total.compareTo(b.total);
            break;
          case 2:
            cmp = a.accuracy.compareTo(b.accuracy);
            break;
          case 3:
            cmp = a.mistakes.compareTo(b.mistakes);
            break;
          case 4:
            cmp = a.rating.compareTo(b.rating);
            break;
          default:
            cmp = 0;
        }
        return _ascending ? cmp : -cmp;
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сравнение паков'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumn,
            sortAscending: _ascending,
            columns: [
              DataColumn(
                label: const Text('Название'),
                onSort: _onSort,
              ),
              DataColumn(
                label: const Text('Рук'),
                numeric: true,
                onSort: _onSort,
              ),
              DataColumn(
                label: const Text('Точность'),
                numeric: true,
                onSort: _onSort,
              ),
              DataColumn(
                label: const Text('Ошибки'),
                numeric: true,
                onSort: _onSort,
              ),
              DataColumn(
                label: const Text('Рейтинг'),
                numeric: true,
                onSort: _onSort,
              ),
            ],
            rows: [
              for (final s in stats)
                DataRow(
                  onSelectChanged: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackReviewScreen(pack: s.pack),
                      ),
                    );
                  },
                  cells: [
                    DataCell(Text(s.name)),
                    DataCell(Text(s.total.toString())),
                    DataCell(Text('${s.accuracy.toStringAsFixed(1)}%')),
                    DataCell(Text(s.mistakes.toString())),
                    DataCell(Text(s.rating.toStringAsFixed(1))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
