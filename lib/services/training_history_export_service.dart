import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/training_spot.dart';
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
}
