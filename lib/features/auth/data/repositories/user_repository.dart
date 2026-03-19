import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/core/models/user_profile_model.dart';

class UserRepository {
  UserRepository._internal();
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> createUserProfile(User user) async {
    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) {
      await _usersCollection.doc(user.uid).set({
        'email': user.email ?? '',
      });
    }
  }

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
      'partnerEmail': partnerEmail,
    });

    // Mutual link: update partner to point back
    await _usersCollection.doc(partnerUid).update({
      'partnerUid': currentUser.uid,
      'partnerEmail': currentUser.email,
    });

    return true;
  }

  Future<void> setRelationshipStartDate(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // Update local user
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
}
