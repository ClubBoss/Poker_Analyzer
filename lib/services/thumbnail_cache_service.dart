import '../models/v2/training_pack_template.dart';
import 'preview_cache_service.dart';

class ThumbnailCacheService {
  ThumbnailCacheService._();
  static final instance = ThumbnailCacheService._();

  final Map<String, Future<String?>> _inFlight = {};
  final Map<String, String?> _cache = {};

  Future<String?> getThumbnail(TrainingPackTemplate template) {
    final id = template.id;
    if (_cache.containsKey(id)) return Future.value(_cache[id]);
    final png = template.png;
    if (png == null) return Future.value(null);
    if (_inFlight.containsKey(id)) return _inFlight[id]!;
    final future = PreviewCacheService.instance.getPreviewPath(png).then((p) {
      _cache[id] = p;
      return p;
    });
    _inFlight[id] = future.whenComplete(() => _inFlight.remove(id));
    return future;
  }

  void invalidate(String id) {
    _cache.remove(id);
  }

  void clear() {
    _cache.clear();
    _inFlight.clear();
  }
}
