import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';

class MemoriesRepository {
  MemoriesRepository._internal();
  static final MemoriesRepository _instance = MemoriesRepository._internal();
  factory MemoriesRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference get _memoriesCollection => _firestore
      .collection('users')
      .doc(_uid)
      .collection(AppConstants.memoriesCollection);

  Stream<List<MemoryModel>> getMemoriesStream() {
    final controller = StreamController<List<MemoryModel>>.broadcast();
    List<MemoryModel> myMemories = [];
    List<MemoryModel> partnerMemories = [];

    void updateAndEmit() {
      final combined = [...myMemories, ...partnerMemories];
      combined.sort((a, b) {
        final tA = a.memoryDate ?? a.timestamp;
        final tB = b.memoryDate ?? b.timestamp;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });
      controller.add(combined);
    }

    StreamSubscription? mySub;
    mySub = _memoriesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          myMemories = snap.docs
              .map((doc) => MemoryModel.fromFirestore(doc))
              .toList();
          updateAndEmit();
        });

    StreamSubscription? partnerSub;
    final userSub = UserRepository().getUserProfileStream().listen((profile) {
      if (profile?.partnerUid != null && partnerSub == null) {
        partnerSub = _firestore
            .collection('users')
            .doc(profile!.partnerUid)
            .collection(AppConstants.memoriesCollection)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snap) {
              partnerMemories = snap.docs
                  .map((doc) => MemoryModel.fromFirestore(doc))
                  .toList();
              updateAndEmit();
            });
      }
    });

    controller.onCancel = () {
      mySub?.cancel();
      partnerSub?.cancel();
      userSub.cancel();
    };

    // Emit initial empty state or try to emit current
    updateAndEmit();

    return controller.stream;
  }

  Future<List<MemoryModel>> getCachedMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(AppConstants.memoriesCacheKey);
    if (cached != null) {
      final List<dynamic> decoded = json.decode(cached);
      return decoded.map((m) => MemoryModel.fromMap(m as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<MemoryModel>> fetchAndCacheMemories() async {
    final snapshot = await _memoriesCollection
        .orderBy('timestamp', descending: true)
        .get();

    final memories = snapshot.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList();

    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = memories.map((m) => m.toMap()).toList();
    await prefs.setString(AppConstants.memoriesCacheKey, json.encode(memoriesJson));

    return memories;
  }

  Future<void> addMemory(MemoryModel memory) async {
    await _memoriesCollection.add(memory.toFirestore());
    // Clear cache to force refresh on next load
    await _clearCache();
  }

  Future<void> updateMemory(MemoryModel memory) async {
    if (memory.id == null) return;
    await _memoriesCollection.doc(memory.id).update(memory.toFirestore());
    await _clearCache();
  }

  Future<void> deleteMemory(String id) async {
    await _memoriesCollection.doc(id).delete();
    await _clearCache();
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.memoriesCacheKey);
  }

  Future<void> seedMemories(List<MemoryModel> seeds) async {
    final batch = _firestore.batch();
    for (var memory in seeds) {
      final docRef = _memoriesCollection.doc();
      batch.set(docRef, memory.toFirestore());
    }
    await batch.commit();
    await _clearCache();
  }
}

  // final seeds = [
  //     "20th Dec : Windy hill",
  //     "27th Dec : Cafe Window pane - came to give flowers diuso",
  //     "31st Dec : Baker's treat",
  //     "3rd January : The dragon's farm - td",
  //     "10th January : Lele - td",
  //     "11th January : Butwal ko fulki - td",
  //     "15th January : kyampa",
  //     "18th January : chocolate dina ako thyo",
  //     "19th January : HaoPin Hotpot - chicken station",
  //     "20th January : organic - Baker's treat",
  //     "22rd January : dalle - barbecue chulo",
  //     "23rd January : buddhanilkantha",
  //     "30th January : Mike's",
  //     "31st January : Workshop eatery",
  //     "7th February : House of sushi",
  //     "8th February : Cafe Jireh - td",
  //     "14th February : Marathon - his home",
  //     "20th February : shrey courtyard - norvic - Car accident",
  //     "21th February : Mahadevsthan - Baker's treat",
  //     "25th February : KGF restro",
  //     "2nd March : holi plus Baker's treat",
  //     "13th March : Butwal ko fulki plus chaya center (crime 101)",
  //     "15th March : Baker's treat 2nd month ann",
  //   ];