import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/core/models/user_profile_model.dart';
import 'package:moodtrack/core/services/fcm_service.dart';

class UserRepository {
  UserRepository._internal();
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    final token = await FcmService().initAndGetToken();
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

  Future<UserProfile?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    log('Firestore: Getting profile for $uid', name: 'Firebase');
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      log('Firestore: Profile not found for $uid', name: 'Firebase');
      return null;
    }
    log('Firestore: Profile retrieved successfully', name: 'Firebase');
    return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ── Linking ───────────────────────────────────────────────────────────────

  Future<bool> linkPartnerByEmail(String partnerEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    if (currentUser.email?.toLowerCase() == partnerEmail.toLowerCase()) return false;

    log('Firestore: Searching for partner with email $partnerEmail', name: 'Firebase');
    // Find partner
    final query = await _usersCollection
        .where('email', isEqualTo: partnerEmail.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      log('Firestore: Partner with email $partnerEmail not found', name: 'Firebase');
      return false;
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
      return true;
    } catch (e) {
      log('Firestore: Error during partner linking: $e', name: 'Firebase');
      return false;
    }
  }

  Future<void> setRelationshipStartDate(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    log('Firestore: Setting relationship start date for $uid', name: 'Firebase');
    try {
      await _usersCollection.doc(uid).update({
        'relationshipStartDate': Timestamp.fromDate(date),
      });

      // Try update partner too if linked
      final profile = await getUserProfile();
      final partnerUid = profile?.partnerUid;
      if (partnerUid != null) {
        log('Firestore: Setting relationship start date for partner $partnerUid', name: 'Firebase');
        await _usersCollection.doc(partnerUid).update({
          'relationshipStartDate': Timestamp.fromDate(date),
        });
      }
      log('Firestore: Relationship start date updated successfully', name: 'Firebase');
    } catch (e) {
      log('Firestore: Error updating relationship start date: $e', name: 'Firebase');
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
