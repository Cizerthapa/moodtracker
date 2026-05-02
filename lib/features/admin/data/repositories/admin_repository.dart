import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodtrack/core/models/user_profile_model.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/models/journal_entry_model.dart';
import 'package:moodtrack/core/error/result.dart';

class AdminRepository {
  AdminRepository();

  static const String adminEmail = 'cizerthapa@gmail.com';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────────────────────────

  Future<Result<Map<String, dynamic>?>> getUserProfile(String uid) async {
    log('Firestore [Admin]: Fetching profile for $uid', name: 'Firebase');
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        log('Firestore [Admin]: Profile for $uid not found', name: 'Firebase');
        return const Success(null);
      }
      final data = doc.data()!;
      data['uid'] = doc.id;
      log('Firestore [Admin]: Profile for $uid retrieved successfully', name: 'Firebase');
      return Success(data);
    } catch (e) {
      log('Firestore [Admin]: Error fetching profile: $e', name: 'Firebase');
      return Failure('Failed to fetch user profile', error: e);
    }
  }

  Future<Result<void>> deleteUserData(String uid) async {
    log('Firestore [Admin]: Deleting all data for $uid', name: 'Firebase');
    try {
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
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error deleting user data: $e', name: 'Firebase');
      return Failure('Failed to delete user data', error: e);
    }
  }

  // ── Full Profile ─────────────────────────────────────────────────────────

  /// Returns a [UserProfile] populated with both journals and memories.
  Future<Result<UserProfile?>> getUserFullProfile(String uid) async {
    try {
      final profileResult = await getUserProfile(uid);
      if (profileResult is Failure) return Failure((profileResult as Failure).message);
      
      final profileData = (profileResult as Success<Map<String, dynamic>?>).data;
      if (profileData == null) return const Success(null);
      
      final profile = UserProfile.fromMap(profileData, uid);
      
      final journalsResult = await getUserJournals(uid);
      if (journalsResult is Failure) return Failure((journalsResult as Failure).message);
      
      final memoriesResult = await getUserMemories(uid);
      if (memoriesResult is Failure) return Failure((memoriesResult as Failure).message);
      
      return Success(profile.withCollections(
        journals: (journalsResult as Success<List<JournalEntry>>).data,
        memories: (memoriesResult as Success<List<MemoryModel>>).data,
      ));
    } catch (e) {
      log('Firestore [Admin]: Error fetching full profile: $e', name: 'Firebase');
      return Failure('Failed to fetch full user profile', error: e);
    }
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

  Future<Result<List<JournalEntry>>> getUserJournals(String uid) async {
    log('Firestore [Admin]: Fetching journals for $uid', name: 'Firebase');
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('journals')
          .orderBy('timestamp', descending: true)
          .get();
      log('Firestore [Admin]: Fetched ${snap.docs.length} journals for $uid', name: 'Firebase');
      final journals = snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
      return Success(journals);
    } catch (e) {
      log('Firestore [Admin]: Error fetching journals: $e', name: 'Firebase');
      return Failure('Failed to fetch user journals', error: e);
    }
  }

  Future<Result<void>> deleteJournal(String uid, String journalId) async {
    log('Firestore [Admin]: Deleting journal $journalId for $uid', name: 'Firebase');
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(journalId)
          .delete();
      log('Firestore [Admin]: Journal $journalId deleted', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error deleting journal: $e', name: 'Firebase');
      return Failure('Failed to delete journal entry', error: e);
    }
  }
  // ── Memories ─────────────────────────────────────────────────────────────

  Future<Result<List<MemoryModel>>> getUserMemories(String uid) async {
    log('Firestore [Admin]: Fetching memories for $uid', name: 'Firebase');
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('memories')
          .orderBy('timestamp', descending: true)
          .get();
      log('Firestore [Admin]: Fetched ${snap.docs.length} memories for $uid', name: 'Firebase');
      final memories = snap.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList();
      return Success(memories);
    } catch (e) {
      log('Firestore [Admin]: Error fetching memories: $e', name: 'Firebase');
      return Failure('Failed to fetch user memories', error: e);
    }
  }

  Future<Result<void>> deleteMemory(String uid, String memoryId) async {
    log('Firestore [Admin]: Deleting memory $memoryId for $uid', name: 'Firebase');
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('memories')
          .doc(memoryId)
          .delete();
      log('Firestore [Admin]: Memory $memoryId deleted', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error deleting memory: $e', name: 'Firebase');
      return Failure('Failed to delete memory entry', error: e);
    }
  }

  Future<Result<void>> updateMemory(
    String uid,
    String memoryId,
    Map<String, dynamic> data,
  ) async {
    log('Firestore [Admin]: Updating memory $memoryId for $uid', name: 'Firebase');
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('memories')
          .doc(memoryId)
          .update(data);
      log('Firestore [Admin]: Memory $memoryId updated', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error updating memory: $e', name: 'Firebase');
      return Failure('Failed to update memory', error: e);
    }
  }

  // ── Broadcast ─────────────────────────────────────────────────────────────

  Future<Result<void>> sendBroadcast(String message, {String type = 'info'}) async {
    log('Firestore [Admin]: Sending broadcast', name: 'Firebase');
    try {
      await _firestore.collection('broadcasts').add({
        'message': message,
        'type': type,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': adminEmail,
      });
      log('Firestore [Admin]: Broadcast added to collection', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error sending broadcast: $e', name: 'Firebase');
      return Failure('Failed to send broadcast', error: e);
    }
  }

  Future<Result<void>> clearBroadcast() async {
    try {
      final snap = await _firestore.collection('broadcasts').get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error clearing broadcasts: $e', name: 'Firebase');
      return Failure('Failed to clear broadcasts', error: e);
    }
  }

  Stream<DocumentSnapshot?> getBroadcastStream() {
    log('Firestore [Admin]: Listening to broadcasts', name: 'Firebase');
    return _firestore
        .collection('broadcasts')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first : null);
  }

  // ── Push Notifications ───────────────────────────────────────────────────

  Future<Result<void>> sendPushNotification(String fcmToken, String title, String body, {Map<String, dynamic>? data}) async {
    log('Firestore [Admin]: Queuing push notification to $fcmToken', name: 'Firebase');
    try {
      await _firestore.collection('push_notifications_queue').add({
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': adminEmail,
      });
      log('Firestore [Admin]: Push notification queued', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log('Firestore [Admin]: Error queuing push notification: $e', name: 'Firebase');
      return Failure('Failed to queue push notification', error: e);
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<Result<Map<String, int>>> getStats() async {
    log('Firestore [Admin]: Fetching global stats', name: 'Firebase');
    try {
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
      return Success({
        'users': usersSnap.size,
        'memories': totalMemories,
        'journals': totalJournals,
      });
    } catch (e) {
      log('Firestore [Admin]: Error getting stats: $e', name: 'Firebase');
      return Failure('Failed to fetch system statistics', error: e);
    }
  }
}
