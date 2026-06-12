import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// [ActivityLogService]:
// What is ActivityLogService?
// ActivityLogService is a service that is used to log the activities of the users.
// It is used to log the activities of the users.

// Why is this important?
// This is important because it is used to track the activities of the users.
class ActivityLogService {
  final FirebaseFirestore _firestore;

  ActivityLogService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> log(String action, {String? userId, Map<String, dynamic>? metadata}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('admin_logs').add({
        'action': action,
        'userId': userId ?? user?.uid,
        'userEmail': user?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      dev.log('ActivityLog: failed to write "$action": $e', name: 'ActivityLog');
    }
  }
}
