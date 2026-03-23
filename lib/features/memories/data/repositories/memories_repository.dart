import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
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

  Stream<List<Map<String, dynamic>>> getMemoriesStream() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>> myMemories = [];
    List<Map<String, dynamic>> partnerMemories = [];

    void updateAndEmit() {
      final combined = [...myMemories, ...partnerMemories];
      combined.sort((a, b) {
        final tA = a['memoryDate'] ?? a['timestamp'];
        final tB = b['memoryDate'] ?? b['timestamp'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        if (tB is! Timestamp || tA is! Timestamp) return 0;
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
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
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
                  .map((doc) => {'id': doc.id, ...doc.data()})
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

  Future<List<Map<String, dynamic>>> getCachedMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(AppConstants.memoriesCacheKey);
    if (cached != null) {
      final List<dynamic> decoded = json.decode(cached);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchAndCacheMemories() async {
    final snapshot = await _memoriesCollection
        .orderBy('timestamp', descending: true)
        .get();

    final memories = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id,
        // Convert timestamp to string for JSON serialization
        'timestamp': (data['timestamp'] as Timestamp?)
            ?.toDate()
            .toIso8601String(),
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.memoriesCacheKey, json.encode(memories));

    return memories;
  }

  Future<void> addMemory({
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
    String? herFavStory,
    String? hisFavStory,
    bool isUnique = false,
    DateTime? memoryDate,
  }) async {
    await _memoriesCollection.add({
      'title': title,
      'description': description,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'herFavStory': herFavStory,
      'hisFavStory': hisFavStory,
      'isUnique': isUnique,
      'memoryDate': memoryDate != null ? Timestamp.fromDate(memoryDate) : null,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Clear cache to force refresh on next load
    await _clearCache();
  }

  Future<void> updateMemory(String id, Map<String, dynamic> data) async {
    await _memoriesCollection.doc(id).update(data);
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

  Future<void> seedMemories(List<Map<String, dynamic>> seeds) async {
    final batch = _firestore.batch();
    for (int i = 0; i < seeds.length; i++) {
      final docRef = _memoriesCollection.doc();
      batch.set(docRef, {
        ...seeds[i],
        'timestamp': FieldValue.serverTimestamp(),
      });
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