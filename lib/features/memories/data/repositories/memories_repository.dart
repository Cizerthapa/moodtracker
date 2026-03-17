import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class MemoriesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _memoriesCollection =>
      _firestore.collection(AppConstants.memoriesCollection);

  Stream<QuerySnapshot> getMemoriesStream() {
    return _memoriesCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
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
        'timestamp': (data['timestamp'] as Timestamp?)?.toDate().toIso8601String(),
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
    bool isUnique = false,
  }) async {
    await _memoriesCollection.add({
      'title': title,
      'description': description,
      'lat': lat,
      'lng': lng,
      'isUnique': isUnique,
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
