import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to the specified path and returns the download URL.
  Future<String?> uploadFile({required File file, required String path}) async {
    log('Storage: Uploading file to $path', name: 'Firebase');
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      log('Storage: File uploaded successfully: $downloadUrl', name: 'Firebase');
      return downloadUrl;
    } catch (e) {
      log("Storage: Error uploading file to storage: $e", name: 'Firebase');
      return null;
    }
  }

  /// Deletes a file from the specified path.
  Future<void> deleteFile(String path) async {
    log('Storage: Deleting file at $path', name: 'Firebase');
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      log('Storage: File deleted successfully', name: 'Firebase');
    } catch (e) {
      log("Storage: Error deleting file from storage: $e", name: 'Firebase');
    }
  }
}
