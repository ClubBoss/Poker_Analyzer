import '../models/training_pack.dart';
import 'training_pack_storage_service.dart';

class SmartSuggestionService {
  final TrainingPackStorageService storage;
  SmartSuggestionService({required this.storage});

  List<TrainingPack> getSuggestions() {
    final now = DateTime.now();
    final list = storage.packs.toList();
    list.sort((a, b) {
      final ascore = (1 - a.pctComplete) * 100 + now.difference(a.lastAttemptDate).inDays;
      final bscore = (1 - b.pctComplete) * 100 + now.difference(b.lastAttemptDate).inDays;
      return bscore.compareTo(ascore);
    });
    return list.take(3).toList();
  }
}
