import '../bootstrap/built_in_pack_seeder.dart';
import '../../../models/v2/training_pack_v2.dart';

class BuiltInLibraryController {
  BuiltInLibraryController._();
  static final instance = BuiltInLibraryController._();

  final BuiltInPackSeeder _seeder = const BuiltInPackSeeder();
  List<TrainingPackV2> _packs = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> preload() async {
    if (_loaded) return;
    _packs = await _seeder.loadBuiltInLibrary();
    _loaded = true;
  }

  List<TrainingPackV2> getPacks() => List.unmodifiable(_packs);
}
