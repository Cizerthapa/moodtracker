import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String? title;
  final String text;
  final String mood;
  final String? imageLocalPath;
  final bool encrypted;
  final DateTime? timestamp;
  final DateTime? lastUpdated;

  const JournalEntry({
    required this.id,
    this.title,
    required this.text,
    required this.mood,
    this.imageLocalPath,
    this.encrypted = false,
    this.timestamp,
    this.lastUpdated,
  });

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      title: data['title'] as String?,
      text: data['text'] as String? ?? '',
      mood: data['mood'] as String? ?? '',
      imageLocalPath: data['imageLocalPath'] as String?,
      encrypted: data['encrypted'] as bool? ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}
