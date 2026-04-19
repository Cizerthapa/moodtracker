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
    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) {
      await _usersCollection.doc(user.uid).set({
        'email': (user.email ?? '').toLowerCase(),
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'platform': _getPlatform(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
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

    await _usersCollection.doc(targetUid).set(
      {
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      },
      SetOptions(merge: true),
    );
  }

  /// Call this on every app launch / auth state change to keep lastSeen fresh.
  Future<void> updateLastSeen() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _usersCollection.doc(uid).set(
      {'lastSeen': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ── Profile Reads ─────────────────────────────────────────────────────────

  Stream<UserProfile?> getUserProfileStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<UserProfile?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ── Linking ───────────────────────────────────────────────────────────────

  Future<bool> linkPartnerByEmail(String partnerEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    if (currentUser.email?.toLowerCase() == partnerEmail.toLowerCase()) return false;

    // Find partner
    final query = await _usersCollection
        .where('email', isEqualTo: partnerEmail.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final partnerDoc = query.docs.first;
    final partnerUid = partnerDoc.id;

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

    return true;
  }

  Future<void> setRelationshipStartDate(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'relationshipStartDate': Timestamp.fromDate(date),
    });

    // Try update partner too if linked
    final profile = await getUserProfile();
    if (profile?.partnerUid != null) {
      await _usersCollection.doc(profile!.partnerUid).update({
        'relationshipStartDate': Timestamp.fromDate(date),
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
