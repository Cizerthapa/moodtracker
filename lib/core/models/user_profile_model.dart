import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? partnerUid;
  final String? partnerEmail;
  final DateTime? relationshipStartDate;

  UserProfile({
    required this.uid,
    required this.email,
    this.partnerUid,
    this.partnerEmail,
    this.relationshipStartDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfile(
      uid: docId,
      email: map['email'] ?? '',
      partnerUid: map['partnerUid'],
      partnerEmail: map['partnerEmail'],
      relationshipStartDate: (map['relationshipStartDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (partnerUid != null) 'partnerUid': partnerUid,
      if (partnerEmail != null) 'partnerEmail': partnerEmail,
      if (relationshipStartDate != null) 'relationshipStartDate': Timestamp.fromDate(relationshipStartDate!),
    };
  }
}
