import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';

class AdminRepository {
  AdminRepository._internal();
  static final AdminRepository _instance = AdminRepository._internal();
  factory AdminRepository() => _instance;

  static const String adminEmail = 'cizerthapa@gmail.com';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  }

  Future<void> deleteUserData(String uid) async {
    // Delete all sub-collections
    final collections = ['memories', 'journal', 'waterIntake', 'notes', 'moodEntries'];
    for (final col in collections) {
      final snap = await _firestore.collection('users').doc(uid).collection(col).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // Delete user document itself
    await _firestore.collection('users').doc(uid).delete();
  }

  // ── Memories ─────────────────────────────────────────────────────────────

  Future<List<MemoryModel>> getUserMemories(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList();
  }

  Future<void> deleteMemory(String uid, String memoryId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .doc(memoryId)
        .delete();
  }

  Future<void> updateMemory(String uid, String memoryId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .doc(memoryId)
        .update(data);
  }

  // ── Broadcast ─────────────────────────────────────────────────────────────

  Future<void> sendBroadcast(String message, {String type = 'info'}) async {
    await _firestore.collection('broadcasts').doc('latest').set({
      'message': message,
      'type': type,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': adminEmail,
    });
  }

  Future<void> clearBroadcast() async {
    await _firestore.collection('broadcasts').doc('latest').delete();
  }

  Stream<DocumentSnapshot> getBroadcastStream() {
    return _firestore.collection('broadcasts').doc('latest').snapshots();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final usersSnap = await _firestore.collection('users').get();
    int totalMemories = 0;
    int totalJournals = 0;

    for (final userDoc in usersSnap.docs) {
      final memSnap = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('memories')
          .get();
      totalMemories += memSnap.size;

      final jSnap = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('journal')
          .get();
      totalJournals += jSnap.size;
    }

    return {
      'users': usersSnap.size,
      'memories': totalMemories,
      'journals': totalJournals,
    };
  }
}
