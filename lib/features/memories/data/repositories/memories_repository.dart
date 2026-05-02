import 'dart:async';
import 'dart:developer';
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
    log('Firestore: Listening to memories for $_uid', name: 'Firebase');
    mySub = _memoriesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          log('Firestore: Received ${snap.docs.length} memories for $_uid', name: 'Firebase');
          myMemories = snap.docs
              .map((doc) => MemoryModel.fromFirestore(doc))
              .toList();
          updateAndEmit();
        });

    StreamSubscription? partnerSub;
    final userSub = UserRepository().getUserProfileStream().listen((profile) {
      final partnerUid = profile?.partnerUid;
      if (partnerUid != null && partnerSub == null) {
        log('Firestore: Listening to partner memories for $partnerUid', name: 'Firebase');
        partnerSub = _firestore
            .collection('users')
            .doc(partnerUid)
            .collection(AppConstants.memoriesCollection)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snap) {
              log('Firestore: Received ${snap.docs.length} partner memories', name: 'Firebase');
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
    log('Firestore: Fetching memories for $_uid', name: 'Firebase');
    final snapshot = await _memoriesCollection
        .orderBy('timestamp', descending: true)
        .get();

    log('Firestore: Fetched ${snapshot.docs.length} memories', name: 'Firebase');
    final memories = snapshot.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList();

    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = memories.map((m) => m.toMap()).toList();
    await prefs.setString(AppConstants.memoriesCacheKey, json.encode(memoriesJson));

    return memories;
  }

  Future<void> addMemory(MemoryModel memory) async {
    log('Firestore: Adding memory for $_uid', name: 'Firebase');
    try {
      await _memoriesCollection.add(memory.toFirestore());
      log('Firestore: Memory added successfully', name: 'Firebase');
      await _clearCache();
    } catch (e) {
      log('Firestore: Error adding memory: $e', name: 'Firebase');
      rethrow;
    }
  }

  Future<void> updateMemory(MemoryModel memory) async {
    if (memory.id == null) return;
    log('Firestore: Updating memory ${memory.id} for $_uid', name: 'Firebase');
    try {
      await _memoriesCollection.doc(memory.id).update(memory.toFirestore());
      log('Firestore: Memory updated successfully', name: 'Firebase');
      await _clearCache();
    } catch (e) {
      log('Firestore: Error updating memory: $e', name: 'Firebase');
      rethrow;
    }
  }

  Future<void> deleteMemory(String id) async {
    log('Firestore: Deleting memory $id for $_uid', name: 'Firebase');
    try {
      await _memoriesCollection.doc(id).delete();
      log('Firestore: Memory deleted successfully', name: 'Firebase');
      await _clearCache();
    } catch (e) {
      log('Firestore: Error deleting memory: $e', name: 'Firebase');
      rethrow;
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.memoriesCacheKey);
  }

  Future<void> seedMemories(List<MemoryModel> seeds) async {
    log('Firestore: Seeding ${seeds.length} memories for $_uid', name: 'Firebase');
    final batch = _firestore.batch();
    for (var memory in seeds) {
      final docRef = _memoriesCollection.doc();
      batch.set(docRef, memory.toFirestore());
    }
    await batch.commit();
    log('Firestore: Seeding batch committed successfully', name: 'Firebase');
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