import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudRetryPolicy {
  static Future<T> execute<T>(Future<T> Function() action) async {
    var delay = 500;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        return await action();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' || e.code == 'not-found') rethrow;
        if (attempt == 4) rethrow;
      } catch (_) {
        if (attempt == 4) rethrow;
      }
      final jitter = Random().nextInt(200) - 100;
      await Future.delayed(Duration(milliseconds: delay + jitter));
      delay *= 2;
    }
    throw StateError('unreachable');
  }
}
