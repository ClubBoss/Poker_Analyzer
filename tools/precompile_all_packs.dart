import 'package:poker_analyzer/services/precompiled_pack_cache_generator.dart';

Future<void> main() async {
  await const PrecompiledPackCacheGenerator().generateAll();
}
