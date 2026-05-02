import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';
import 'package:moodtrack/features/period/domain/model/period_cycle_model.dart';

class PeriodRepository {
  PeriodRepository._internal();
  static final PeriodRepository _instance = PeriodRepository._internal();
  factory PeriodRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference get _periodsCollection => _firestore
      .collection('users')
      .doc(_uid)
      .collection(AppConstants.periodsCollection);

  /// Streams both the user's cycles and (read-only) the partner's cycles,
  /// sorted by startDate descending.
  Stream<List<PeriodCycle>> getPeriodsStream() {
    final controller = StreamController<List<PeriodCycle>>.broadcast();
    List<PeriodCycle> myCycles = [];
    List<PeriodCycle> partnerCycles = [];

    void emit() {
      final combined = [...myCycles, ...partnerCycles];
      combined.sort((a, b) => b.startDate.compareTo(a.startDate));
      controller.add(combined);
    }

    StreamSubscription? mySub;
    log('Firestore: Listening to periods for $_uid', name: 'Firebase');
    mySub = _periodsCollection
        .orderBy('startDate', descending: true)
        .snapshots()
        .listen((snap) {
          log('Firestore: Received ${snap.docs.length} periods for $_uid', name: 'Firebase');
          myCycles =
              snap.docs.map((d) => PeriodCycle.fromFirestore(d)).toList();
          emit();
        });

    StreamSubscription? partnerSub;
    final profileSub =
        UserRepository().getUserProfileStream().listen((profile) {
          if (profile?.partnerUid != null && partnerSub == null) {
            log('Firestore: Listening to partner periods for ${profile!.partnerUid}', name: 'Firebase');
            partnerSub = _firestore
                .collection('users')
                .doc(profile.partnerUid)
                .collection(AppConstants.periodsCollection)
                .orderBy('startDate', descending: true)
                .snapshots()
                .listen((snap) {
                  log('Firestore: Received ${snap.docs.length} partner periods', name: 'Firebase');
                  partnerCycles =
                      snap.docs.map((d) => PeriodCycle.fromFirestore(d)).toList();
                  emit();
                });
          }
        });

    controller.onCancel = () {
      mySub?.cancel();
      partnerSub?.cancel();
      profileSub.cancel();
    };

    emit();
    return controller.stream;
  }

  Future<void> addCycle(PeriodCycle cycle) async {
    log('Firestore: Adding cycle for $_uid', name: 'Firebase');
    await _periodsCollection.add(cycle.toFirestore());
    log('Firestore: Cycle added successfully', name: 'Firebase');
  }

  Future<void> updateCycle(PeriodCycle cycle) async {
    if (cycle.id == null) return;
    log('Firestore: Updating cycle ${cycle.id} for $_uid', name: 'Firebase');
    await _periodsCollection.doc(cycle.id).update(cycle.toFirestore());
    log('Firestore: Cycle updated successfully', name: 'Firebase');
  }

  Future<void> deleteCycle(String id) async {
    log('Firestore: Deleting cycle $id for $_uid', name: 'Firebase');
    await _periodsCollection.doc(id).delete();
    log('Firestore: Cycle deleted successfully', name: 'Firebase');
  }
}
