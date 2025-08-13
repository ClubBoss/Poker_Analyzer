import '../models/eval_result.dart';

/// Simple in-memory cache for [EvalResult]s keyed by request hash.
class EvaluationCache {
  final Map<String, EvalResult> _cache = {};

  /// Retrieves a cached result for [key] if present.
  EvalResult? get(String key) => _cache[key];

  /// Stores [value] in cache for [key].
  void set(String key, EvalResult value) => _cache[key] = value;

  /// Clears all cached results.
  void clear() => _cache.clear();
}
