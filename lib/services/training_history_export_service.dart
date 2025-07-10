import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import 'training_spot_storage_service.dart';

class TrainingHistoryExportService {
  TrainingHistoryExportService({TrainingSpotStorageService? storage})
      : _storage = storage ?? TrainingSpotStorageService();

  final TrainingSpotStorageService _storage;

  Future<File> exportToJson() async {
    final spots = await _storage.load();
    spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = spots.take(100);
    final data = [
      for (final s in recent)
        {
          'playerCards': [
            for (final list in s.playerCards)
              [for (final c in list) {'rank': c.rank, 'suit': c.suit}]
          ],
          'actions': [
            for (final a in s.actions)
              {
                'street': a.street,
                'playerIndex': a.playerIndex,
                'action': a.action,
                if (a.amount != null) 'amount': a.amount,
              }
          ],
          'heroIndex': s.heroIndex,
          if (s.userAction != null) 'userAction': s.userAction,
          if (s.recommendedAction != null)
            'evalResult': {
              'recommended': s.recommendedAction,
              if (s.recommendedAmount != null)
                'amount': s.recommendedAmount,
              if (s.userAction != null)
                'correct': s.userAction == s.recommendedAction,
            },
        }
    ];
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  Future<File> exportToCsv() async {
    final spots = await _storage.load();
    spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = spots.take(100);
    final rows = <List<dynamic>>[];
    rows.add(['Player cards', 'Action', 'Hero index', 'Result']);
    for (final s in recent) {
      final cards = s.playerCards
          .map((pc) => pc.map((c) => c.toString()).join(' '))
          .join('|');
      final action = s.userAction ?? '';
      String result = '';
      if (s.recommendedAction != null && s.userAction != null) {
        result = s.userAction == s.recommendedAction ? 'correct' : 'incorrect';
      }
      rows.add([cards, action, s.heroIndex, result]);
    }
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_export.csv');
    await file.writeAsString(csvStr, encoding: utf8);
    return file;
  }
}
