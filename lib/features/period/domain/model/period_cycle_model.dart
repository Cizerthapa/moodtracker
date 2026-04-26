import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodCycle {
  final String? id;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> symptoms;
  final int flowLevel; // 1=light, 2=medium, 3=heavy
  final String? notes;
  final String ownerUid;
  final DateTime? timestamp;

  const PeriodCycle({
    this.id,
    required this.startDate,
    this.endDate,
    this.symptoms = const [],
    this.flowLevel = 2,
    this.notes,
    required this.ownerUid,
    this.timestamp,
  });

  int get durationDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  bool get isOngoing => endDate == null;

  bool isActiveOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (endDate == null) return d == start;
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  factory PeriodCycle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PeriodCycle(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      symptoms: List<String>.from(data['symptoms'] ?? []),
      flowLevel: data['flowLevel'] as int? ?? 2,
      notes: data['notes'] as String?,
      ownerUid: data['ownerUid'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'symptoms': symptoms,
      'flowLevel': flowLevel,
      'notes': notes,
      'ownerUid': ownerUid,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }

  PeriodCycle copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? symptoms,
    int? flowLevel,
    String? notes,
    String? ownerUid,
    DateTime? timestamp,
    bool clearEndDate = false,
  }) {
    return PeriodCycle(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      symptoms: symptoms ?? this.symptoms,
      flowLevel: flowLevel ?? this.flowLevel,
      notes: notes ?? this.notes,
      ownerUid: ownerUid ?? this.ownerUid,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PeriodCycle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
