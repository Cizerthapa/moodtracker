import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/services/encryption_service.dart';

class JournalRepository {
  JournalRepository._internal();
  static final JournalRepository _instance = JournalRepository._internal();
  factory JournalRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryption = EncryptionService.instance;

  static const String _encryptionPrefKey = 'journal_encryption_enabled';

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference get _journalsCollection =>
      _firestore.collection('users').doc(_uid).collection('journals');

  // ── Encryption preference ───────────────────────────────────────────────────

  Future<bool> getEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_encryptionPrefKey) ?? false;
  }

  Future<void> setEncryptionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_encryptionPrefKey, value);
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> getJournalsStream() {
    return _journalsCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addJournal({
    required String text,
    required String mood,
    String? imageLocalPath,
    bool encrypt = false,
  }) async {
    final content = encrypt ? _encryption.encrypt(text, _uid) : text;
    await _journalsCollection.add({
      'text': content,
      'mood': mood,
      'imageLocalPath': imageLocalPath,
      'encrypted': encrypt,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJournal(String id) async {
    await _journalsCollection.doc(id).delete();
  }

  /// Decrypts text if the document is marked as encrypted.
  String decryptIfNeeded(Map<String, dynamic> data) {
    final isEncrypted = data['encrypted'] == true;
    final text = data['text'] as String? ?? '';
    if (isEncrypted) {
      return _encryption.decrypt(text, _uid);
    }
    return text;
  }

  // ── Migration ──────────────────────────────────────────────────────────────

  /// Called when the user toggles encryption. Re-encrypts or decrypts all entries.
  Future<void> migrateEncryption(bool enableEncryption) async {
    final snapshot = await _journalsCollection.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final currentlyEncrypted = data['encrypted'] == true;
      final currentText = data['text'] as String? ?? '';

      if (enableEncryption && !currentlyEncrypted) {
        // Encrypt plain text
        batch.update(doc.reference, {
          'text': _encryption.encrypt(currentText, _uid),
          'encrypted': true,
        });
      } else if (!enableEncryption && currentlyEncrypted) {
        // Decrypt encrypted text
        batch.update(doc.reference, {
          'text': _encryption.decrypt(currentText, _uid),
          'encrypted': false,
        });
      }
    }
    await batch.commit();
  }
}
