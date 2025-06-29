import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cloud_training_session.dart';

class CloudTrainingSessionImportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<CloudTrainingSession?> importFromJson(File file) async {
    if (_uid == null) return null;
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! Map<String, dynamic>) return null;
      final session = CloudTrainingSession.fromJson(
        Map<String, dynamic>.from(data),
        path: '',
      );
      await _db
          .collection('users')
          .doc(_uid)
          .collection('training_sessions')
          .add(session.toJson());
      return session;
    } catch (_) {
      return null;
    }
  }
}
