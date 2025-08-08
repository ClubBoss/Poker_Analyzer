import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages simple transactional writes to [LearningPathStore] using a journal
/// and snapshot file to allow rollback on failure.
class PathTransactionManager {
  final String rootDir;
  const PathTransactionManager({required this.rootDir});

  String _journalPath(String userId) => '$rootDir/.journal.$userId.jsonl';
  String _snapshotPath(String userId, String txId) =>
      '$rootDir/.snapshot.$userId.$txId.json';
  String _storePath(String userId) => '$rootDir/$userId.json';

  Future<String> begin(String userId, String sig) async {
    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    final journal = File(_journalPath(userId));
    journal.parent.createSync(recursive: true);
    await journal.writeAsString(jsonEncode({
      'txId': txId,
      'sig': sig,
      'status': 'pending',
      'modules': <String>[],
    }));
    final store = File(_storePath(userId));
    final snap = File(_snapshotPath(userId, txId));
    if (store.existsSync()) {
      await store.copy(snap.path);
    } else {
      await snap.writeAsString('[]');
    }
    return txId;
  }

  Future<void> recordModule(String userId, String txId, String moduleId) async {
    final journal = File(_journalPath(userId));
    if (!journal.existsSync()) return;
    final data =
        Map<String, dynamic>.from(jsonDecode(await journal.readAsString()));
    final modules = (data['modules'] as List).cast<String>();
    modules.add(moduleId);
    data['modules'] = modules;
    await journal.writeAsString(jsonEncode(data));
  }

  Future<void> commit(String userId, String txId) async {
    final journal = File(_journalPath(userId));
    if (!journal.existsSync()) return;
    final data =
        Map<String, dynamic>.from(jsonDecode(await journal.readAsString()));
    data['status'] = 'committed';
    await journal.writeAsString(jsonEncode(data));
    final snap = File(_snapshotPath(userId, txId));
    if (snap.existsSync()) await snap.delete();
    // prune old journals
    final prefs = await SharedPreferences.getInstance();
    final keep = prefs.getInt('path.journal.keep') ?? 20;
    final dir = Directory(rootDir);
    final journals = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('.journal.$userId'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (journals.length > keep) {
      for (final f in journals.take(journals.length - keep)) {
        f.deleteSync();
      }
    }
    await journal.delete();
  }

  Future<void> rollback(String userId, String txId) async {
    final snap = File(_snapshotPath(userId, txId));
    final store = File(_storePath(userId));
    if (snap.existsSync()) {
      await snap.copy(store.path);
      await snap.delete();
    } else {
      if (store.existsSync()) await store.delete();
    }
    final journal = File(_journalPath(userId));
    if (journal.existsSync()) await journal.delete();
  }

  /// Reconcile unfinished transactions, rolling back any pending ones.
  Future<void> reconcile(String userId) async {
    final journal = File(_journalPath(userId));
    if (!journal.existsSync()) return;
    final data =
        Map<String, dynamic>.from(jsonDecode(await journal.readAsString()));
    if (data['status'] != 'committed') {
      final txId = data['txId'] as String?;
      if (txId != null) {
        await rollback(userId, txId);
      }
    } else {
      await journal.delete();
    }
  }
}
