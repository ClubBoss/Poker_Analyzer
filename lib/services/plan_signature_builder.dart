import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_training_planner.dart';

/// Builds a deterministic signature for a planner run based on
/// canonicalized inputs. The signature is used to guarantee idempotent
/// plan->inject operations across retries and crashes.
class PlanSignatureBuilder {
  static const _sigKeyPrefix = 'planner.sigs.';

  const PlanSignatureBuilder();

  /// Builds a canonical signature for [plan]. The signature is the SHA-256
  /// hash (hex) of a canonical JSON representation containing only the
  /// fields relevant for idempotency.
  ///
  /// The generated signature is stored in [SharedPreferences] keeping only the
  /// most recent 5 signatures per user.
  Future<String> build({
    required String userId,
    required AdaptivePlan plan,
    required String audience,
    required String format,
    required int budgetMinutes,
    String? templateSetVersion,
    String? usfVersion,
  }) async {
    final obj = {
      'version': 2,
      'audience': audience,
      'format': format,
      'budget': budgetMinutes,
      'chosenTags': (plan.tagWeights.keys.toList()..sort()),
      'mix': plan.mix,
      'templateSetVersion': templateSetVersion ?? '',
      'usfVersion': usfVersion ?? '',
    };
    final canonical = jsonEncode(obj);
    final sig = sha256.convert(utf8.encode(canonical)).toString();

    final prefs = await SharedPreferences.getInstance();
    final key = '$_sigKeyPrefix$userId';
    final list = prefs.getStringList(key) ?? <String>[];
    list.add(sig);
    if (list.length > 5) {
      list.removeRange(0, list.length - 5);
    }
    await prefs.setStringList(key, list);
    return sig;
  }
}
