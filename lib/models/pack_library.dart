import 'v2/training_pack_template_v2.dart';

/// Simple in-memory library used for staging imported packs.
class PackLibrary {
  PackLibrary._();

  static final PackLibrary staging = PackLibrary._();

  final List<TrainingPackTemplateV2> _packs = [];
  final Map<String, TrainingPackTemplateV2> _index = {};

  List<TrainingPackTemplateV2> get packs => List.unmodifiable(_packs);

  void clear() {
    _packs.clear();
    _index.clear();
  }

  void add(TrainingPackTemplateV2 pack) {
    if (_index.containsKey(pack.id)) return;
    _packs.add(pack);
    _index[pack.id] = pack;
  }

  void addAll(Iterable<TrainingPackTemplateV2> list) {
    for (final p in list) {
      add(p);
    }
  }

  /// Removes a template with the given [id] from the library.
  void remove(String id) {
    final tpl = _index.remove(id);
    if (tpl != null) _packs.remove(tpl);
  }

  TrainingPackTemplateV2? getById(String id) => _index[id];
}
