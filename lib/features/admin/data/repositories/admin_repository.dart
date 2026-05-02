import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodtrack/core/models/user_profile_model.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/models/journal_entry_model.dart';

class AdminRepository {
  AdminRepository._internal();
  static final AdminRepository _instance = AdminRepository._internal();
  factory AdminRepository() => _instance;

  static const String adminEmail = 'cizerthapa@gmail.com';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    log('Firestore [Admin]: Fetching profile for $uid', name: 'Firebase');
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      log('Firestore [Admin]: Profile for $uid not found', name: 'Firebase');
      return null;
    }
    final data = doc.data()!;
    data['uid'] = doc.id;
    log('Firestore [Admin]: Profile for $uid retrieved successfully', name: 'Firebase');
    return data;
  }

  Future<void> deleteUserData(String uid) async {
    log('Firestore [Admin]: Deleting all data for $uid', name: 'Firebase');
    // Delete all sub-collections
    final collections = [
      'memories',
      'journal',
      'waterIntake',
      'notes',
      'moodEntries',
    ];
    for (final col in collections) {
      log('Firestore [Admin]: Deleting sub-collection $col for $uid', name: 'Firebase');
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection(col)
          .get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      log('Firestore [Admin]: Sub-collection $col deleted', name: 'Firebase');
    }
    // Delete user document itself
    log('Firestore [Admin]: Deleting user document $uid', name: 'Firebase');
    await _firestore.collection('users').doc(uid).delete();
    log('Firestore [Admin]: User $uid fully deleted', name: 'Firebase');
  }

  // ── Full Profile ─────────────────────────────────────────────────────────

  /// Returns a [UserProfile] populated with both journals and memories.
  Future<UserProfile?> getUserFullProfile(String uid) async {
    final profileData = await getUserProfile(uid);
    if (profileData == null) return null;
    final profile = UserProfile.fromMap(profileData, uid);
    final journals = await getUserJournals(uid);
    final memories = await getUserMemories(uid);
    return profile.withCollections(journals: journals, memories: memories);
  }
  // ── Fix: return Stream<List<UserProfile>> instead of raw maps ──────────────

  Stream<List<UserProfile>> getAllUsersStream() {
    log('Firestore [Admin]: Listening to all users', name: 'Firebase');
    return _firestore.collection('users').snapshots().map((snap) {
      log('Firestore [Admin]: Received all users snapshot (${snap.docs.length} users)', name: 'Firebase');
      return snap.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return UserProfile.fromMap(data, doc.id);
      }).toList();
    });
  }

  // ── Journals ──────────────────────────────────────────────────────────────

  Future<List<JournalEntry>> getUserJournals(String uid) async {
    log('Firestore [Admin]: Fetching journals for $uid', name: 'Firebase');
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .orderBy('timestamp', descending: true)
        .get();
    log('Firestore [Admin]: Fetched ${snap.docs.length} journals for $uid', name: 'Firebase');
    return snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
  }

  Future<void> deleteJournal(String uid, String journalId) async {
    log('Firestore [Admin]: Deleting journal $journalId for $uid', name: 'Firebase');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journalId)
        .delete();
    log('Firestore [Admin]: Journal $journalId deleted', name: 'Firebase');
  }
  // ── Memories ─────────────────────────────────────────────────────────────

  Future<List<MemoryModel>> getUserMemories(String uid) async {
    log('Firestore [Admin]: Fetching memories for $uid', name: 'Firebase');
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .orderBy('timestamp', descending: true)
        .get();
    log('Firestore [Admin]: Fetched ${snap.docs.length} memories for $uid', name: 'Firebase');
    return snap.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList();
  }

  Future<void> deleteMemory(String uid, String memoryId) async {
    log('Firestore [Admin]: Deleting memory $memoryId for $uid', name: 'Firebase');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .doc(memoryId)
        .delete();
    log('Firestore [Admin]: Memory $memoryId deleted', name: 'Firebase');
  }

  Future<void> updateMemory(
    String uid,
    String memoryId,
    Map<String, dynamic> data,
  ) async {
    log('Firestore [Admin]: Updating memory $memoryId for $uid', name: 'Firebase');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .doc(memoryId)
        .update(data);
    log('Firestore [Admin]: Memory $memoryId updated', name: 'Firebase');
  }

  // ── Broadcast ─────────────────────────────────────────────────────────────

  Future<void> sendBroadcast(String message, {String type = 'info'}) async {
    log('Firestore [Admin]: Sending broadcast', name: 'Firebase');
    await _firestore.collection('broadcasts').doc('latest').set({
      'message': message,
      'type': type,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': adminEmail,
    });
    log('Firestore [Admin]: Broadcast sent', name: 'Firebase');
  }

  Future<void> clearBroadcast() async {
    await _firestore.collection('broadcasts').doc('latest').delete();
  }

  Stream<DocumentSnapshot> getBroadcastStream() {
    log('Firestore [Admin]: Listening to broadcasts', name: 'Firebase');
    return _firestore.collection('broadcasts').doc('latest').snapshots();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    log('Firestore [Admin]: Fetching global stats', name: 'Firebase');
    final usersSnap = await _firestore.collection('users').get();
    log('Firestore [Admin]: Fetched ${usersSnap.size} users', name: 'Firebase');
    int totalMemories = 0;
    int totalJournals = 0;

    for (final userDoc in usersSnap.docs) {
      log('Firestore [Admin]: Fetching counts for user ${userDoc.id}', name: 'Firebase');
      final memSnap = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('memories')
          .get();
      totalMemories += memSnap.size;

      final jSnap = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('journals')
          .get();
      totalJournals += jSnap.size;
    }

    log('Firestore [Admin]: Stats retrieved - Users: ${usersSnap.size}, Memories: $totalMemories, Journals: $totalJournals', name: 'Firebase');
    return {
      'users': usersSnap.size,
      'memories': totalMemories,
      'journals': totalJournals,
    };
  }
}
