import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:moodtrack/core/error/result.dart';

class StorageService {
  StorageService();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to the specified path and returns the download URL.
  Future<Result<String>> uploadFile({required File file, required String path}) async {
    log('Storage: Uploading file to $path', name: 'Firebase');
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      log('Storage: File uploaded successfully: $downloadUrl', name: 'Firebase');
      return Success(downloadUrl);
    } catch (e) {
      log("Storage: Error uploading file: $e", name: 'Firebase');
      return Failure('Failed to upload image', error: e);
    }
  }

  /// Deletes a file from the specified path.
  Future<Result<void>> deleteFile(String path) async {
    log('Storage: Deleting file at $path', name: 'Firebase');
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      log('Storage: File deleted successfully', name: 'Firebase');
      return const Success(null);
    } catch (e) {
      log("Storage: Error deleting file: $e", name: 'Firebase');
      return Failure('Failed to delete storage file', error: e);
    }
  }
}
