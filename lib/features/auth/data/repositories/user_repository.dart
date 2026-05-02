import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/core/models/user_profile_model.dart';
import 'package:moodtrack/core/services/fcm_service.dart';

import 'package:moodtrack/core/error/result.dart';
import 'package:moodtrack/core/di/service_locator.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? sl<FirebaseFirestore>(),
        _auth = auth ?? sl<FirebaseAuth>();

  CollectionReference get _usersCollection => _firestore.collection('users');

  // ── Profile Creation ──────────────────────────────────────────────────────

  /// Called once after sign-up. Creates the document only if it doesn't exist.
  Future<void> createUserProfile(User user) async {
    log('Firestore: Getting profile for ${user.uid}', name: 'Firebase');
    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) {
      log('Firestore: Creating profile for ${user.uid}', name: 'Firebase');
      await _usersCollection.doc(user.uid).set({
        'email': (user.email ?? '').toLowerCase(),
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'platform': _getPlatform(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
      log('Firestore: Profile created successfully', name: 'Firebase');
    }
    // Always refresh the FCM token on creation
    await refreshFcmToken(user.uid);
  }

  // ── FCM Token ─────────────────────────────────────────────────────────────

  /// Gets a fresh FCM token and writes it to Firestore.
  Future<void> refreshFcmToken([String? uid]) async {
    final targetUid = uid ?? _auth.currentUser?.uid;
    if (targetUid == null) return;

    final token = await sl<FcmService>().initAndGetToken();
    if (token == null) return;

    log('Firestore: Refreshing FCM token for $targetUid', name: 'Firebase');
    await _usersCollection.doc(targetUid).set(
      {
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      },
      SetOptions(merge: true),
    );
    log('Firestore: FCM token refreshed successfully', name: 'Firebase');
  }

  /// Call this on every app launch / auth state change to keep lastSeen fresh.
  Future<void> updateLastSeen() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    log('Firestore: Updating lastSeen for $uid', name: 'Firebase');
    await _usersCollection.doc(uid).set(
      {'lastSeen': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    log('Firestore: lastSeen updated successfully', name: 'Firebase');
  }

  // ── Profile Reads ─────────────────────────────────────────────────────────

  Stream<UserProfile?> getUserProfileStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    log('Firestore: Listening to profile for $uid', name: 'Firebase');
    return _usersCollection.doc(uid).snapshots().map((doc) {
      log('Firestore: Received profile snapshot for $uid', name: 'Firebase');
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<Result<UserProfile?>> getUserProfile({bool forceRefresh = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Failure('User not authenticated');
    
    log('Firestore: Getting profile for $uid (forceRefresh: $forceRefresh)', name: 'Firebase');
    try {
      final source = forceRefresh ? Source.server : Source.serverAndCache;
      final doc = await _usersCollection.doc(uid).get(GetOptions(source: source));
      
      if (!doc.exists || doc.data() == null) {
        log('Firestore: Profile not found for $uid', name: 'Firebase');
        return const Success(null);
      }
      log('Firestore: Profile retrieved successfully from ${doc.metadata.isFromCache ? "cache" : "server"}', name: 'Firebase');
      return Success(UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id));
    } catch (e) {
      log('Firestore: Error getting profile: $e', name: 'Firebase');
      return Failure('Failed to get profile', error: e);
    }
  }

  // ── Linking ───────────────────────────────────────────────────────────────

  Future<Result<bool>> linkPartnerByEmail(String partnerEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Failure('User not authenticated');
    if (currentUser.email?.toLowerCase() == partnerEmail.toLowerCase()) {
      return const Failure('You cannot link with yourself');
    }

    log('Firestore: Searching for partner with email $partnerEmail', name: 'Firebase');
    // Find partner
    final query = await _usersCollection
        .where('email', isEqualTo: partnerEmail.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      log('Firestore: Partner with email $partnerEmail not found', name: 'Firebase');
      return const Failure('Partner not found');
    }

    final partnerDoc = query.docs.first;
    final partnerUid = partnerDoc.id;

    log('Firestore: Linking user ${currentUser.uid} with partner $partnerUid', name: 'Firebase');
    try {
      // Update current user
      await _usersCollection.doc(currentUser.uid).update({
        'partnerUid': partnerUid,
        'partnerEmail': partnerEmail.toLowerCase(),
      });

      // Mutual link: update partner to point back
      await _usersCollection.doc(partnerUid).update({
        'partnerUid': currentUser.uid,
        'partnerEmail': currentUser.email?.toLowerCase(),
      });

      log('Firestore: Mutual link established successfully', name: 'Firebase');
      return const Success(true);
    } catch (e) {
      log('Firestore: Error during partner linking: $e', name: 'Firebase');
      return Failure('Failed to link partner', error: e);
    }
  }

  Future<Result<void>> setRelationshipStartDate(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Failure('User not authenticated');

    log('Firestore: Setting relationship start date for $uid', name: 'Firebase');
    try {
      await _usersCollection.doc(uid).update({
        'relationshipStartDate': Timestamp.fromDate(date),
      });

      // Try update partner too if linked
      final result = await getUserProfile();
      if (result is Success<UserProfile?>) {
        final partnerUid = result.data?.partnerUid;
        if (partnerUid != null) {
          log('Firestore: Setting relationship start date for partner $partnerUid', name: 'Firebase');
          await _usersCollection.doc(partnerUid).update({
            'relationshipStartDate': Timestamp.fromDate(date),
          });
        }
      }
      log('Firestore: Relationship start date updated successfully', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log('Firestore: Error updating relationship start date: $e', name: 'Firebase');
      return Failure('Failed to update relationship date', error: e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
