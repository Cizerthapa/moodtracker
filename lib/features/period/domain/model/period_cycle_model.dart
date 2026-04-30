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

enum CyclePhase {
  menstrual,
  follicular,
  ovulatory,
  luteal,
}

extension CyclePhaseHelper on PeriodCycle {
  CyclePhase getCurrentPhase(DateTime date, int avgCycleLength) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final dayOfCycle = d.difference(start).inDays + 1;

    // Menstrual Phase is active during bleeding days (durationDays)
    // or fallback to 5 days if duration is 1 but it's not ongoing?
    // Let's rely on isActiveOn if we can, but dayOfCycle <= durationDays is good if it's over.
    // Wait, durationDays is accurate if it has ended. If it hasn't, we can just say if it's ongoing, it's menstrual.
    if (dayOfCycle >= 1 && (isOngoing || dayOfCycle <= durationDays)) {
      // If it's a very long cycle where they haven't stopped it, let's cap Menstrual to something reasonable like 10 days max to prevent indefinite menstrual phase if user forgets to log end.
      if (dayOfCycle <= 10) {
        return CyclePhase.menstrual;
      }
    }

    final lutealPhaseStart = avgCycleLength - 13;
    final ovulationWindowStart = avgCycleLength - 18;

    if (dayOfCycle >= lutealPhaseStart) {
      return CyclePhase.luteal;
    } else if (dayOfCycle >= ovulationWindowStart) {
      return CyclePhase.ovulatory;
    } else {
      return CyclePhase.follicular;
    }
  }
}
