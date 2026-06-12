import 'dart:io';
import 'dart:developer' as dev;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class NoteImageService {
  // Separator between fileName and networkUrl stored in the imageUrl DB field.
  // Firebase URLs never contain "||" so this is safe.
  static const _sep = '||';

  // ── Encode / decode ─────────────────────────────────────────────────────

  static String encode(String fileName, String networkUrl) =>
      '$fileName$_sep$networkUrl';

  /// Returns the local filename (e.g. "note3_1.jpg") from an encoded value,
  /// or null if the value is in the old plain-URL format.
  static String? fileNameOf(String? encoded) {
    if (encoded == null || !encoded.contains(_sep)) return null;
    return encoded.split(_sep)[0];
  }

  /// Returns the Firebase Storage URL from an encoded or plain value.
  static String? networkUrlOf(String? encoded) {
    if (encoded == null) return null;
    if (!encoded.contains(_sep)) return encoded; // old plain-URL format
    return encoded.split(_sep)[1];
  }

  // ── Directory ────────────────────────────────────────────────────────────

  Future<Directory> get _dir async {
    late Directory base;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        // ext.path  = /storage/emulated/0/Android/data/{pkg}/files
        // root path = /storage/emulated/0
        final root = ext.path.split('/Android/')[0];
        base = Directory('$root/Download/moodtracker');
      } else {
        final docs = await getApplicationDocumentsDirectory();
        base = Directory('${docs.path}/moodtracker');
      }
    } else {
      final docs = await getApplicationDocumentsDirectory();
      base = Directory('${docs.path}/moodtracker');
    }
    if (!await base.exists()) await base.create(recursive: true);
    return base;
  }

  // ── Filename generation ───────────────────────────────────────────────────

  /// Generates the next sequential filename by counting existing .jpg files.
  Future<String> generateFileName() async {
    final dir = await _dir;
    final count = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .length;
    return 'note${count + 1}_1.jpg';
  }

  // ── Local file operations ─────────────────────────────────────────────────

  /// Copies [source] into the persistent folder under [fileName].
  Future<String> saveLocally(File source, String fileName) async {
    final dir = await _dir;
    final dest = File('${dir.path}/$fileName');
    await source.copy(dest.path);
    dev.log('NoteImage: saved locally → ${dest.path}', name: 'NoteImageService');
    return dest.path;
  }

  /// Returns the [File] if it already exists in the persistent folder, else null.
  Future<File?> getLocalFile(String fileName) async {
    final dir = await _dir;
    final file = File('${dir.path}/$fileName');
    return await file.exists() ? file : null;
  }

  /// Downloads [networkUrl] from Firebase Storage and saves it as [fileName].
  Future<File?> downloadAndCache(String networkUrl, String fileName) async {
    try {
      final dir = await _dir;
      final dest = File('${dir.path}/$fileName');
      final ref = FirebaseStorage.instance.refFromURL(networkUrl);
      await ref.writeToFile(dest);
      dev.log('NoteImage: downloaded → ${dest.path}', name: 'NoteImageService');
      return dest;
    } catch (e) {
      dev.log('NoteImage: download failed: $e', name: 'NoteImageService');
      return null;
    }
  }
}
