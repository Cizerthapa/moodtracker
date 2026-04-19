import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? partnerUid;
  final String? partnerEmail;
  final DateTime? relationshipStartDate;
  final String? fcmToken;
  final DateTime? lastSeen;
  final String? platform; // 'android' | 'ios' | 'web'
  final String? appVersion;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.partnerUid,
    this.partnerEmail,
    this.relationshipStartDate,
    this.fcmToken,
    this.lastSeen,
    this.platform,
    this.appVersion,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfile(
      uid: docId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      partnerUid: map['partnerUid'] as String?,
      partnerEmail: map['partnerEmail'] as String?,
      relationshipStartDate: (map['relationshipStartDate'] as Timestamp?)?.toDate(),
      fcmToken: map['fcmToken'] as String?,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      platform: map['platform'] as String?,
      appVersion: map['appVersion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (partnerUid != null) 'partnerUid': partnerUid,
      if (partnerEmail != null) 'partnerEmail': partnerEmail,
      if (relationshipStartDate != null)
        'relationshipStartDate': Timestamp.fromDate(relationshipStartDate!),
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? partnerUid,
    String? partnerEmail,
    DateTime? relationshipStartDate,
    String? fcmToken,
    DateTime? lastSeen,
    String? platform,
    String? appVersion,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      partnerUid: partnerUid ?? this.partnerUid,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      relationshipStartDate: relationshipStartDate ?? this.relationshipStartDate,
      fcmToken: fcmToken ?? this.fcmToken,
      lastSeen: lastSeen ?? this.lastSeen,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
