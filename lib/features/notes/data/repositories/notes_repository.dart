import 'dart:developer' as dev;
import 'package:moodtrack/core/database/local_database.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/error/result.dart';

class NotesRepository {
  final AppDatabase _db = sl<AppDatabase>();

  NotesRepository();

  Future<Result<List<Map<String, dynamic>>>> getNotes() async {
    dev.log('LocalDB: Fetching all notes', name: 'NotesRepository');
    try {
      final List<Note> driftNotes = await _db.getAllNotes();

      // Sort by date descending (newest first) while they are still Note objects
      driftNotes.sort((a, b) => b.date.compareTo(a.date));

      // Convert Drift models back to Maps for UI compatibility
      final notes = driftNotes
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'text': n.textContent,
              'mood': n.mood,
              'imageUrl': n.imageUrl,
              'date': n.date.toIso8601String(),
              'pendingSync': n.pendingSync,
            },
          )
          .toList();

      dev.log(
        'LocalDB: Retrieved ${notes.length} notes',
        name: 'NotesRepository',
      );
      return Success(notes);
    } catch (e) {
      dev.log('LocalDB: Error getting notes: $e', name: 'NotesRepository');
      return Failure('Failed to load notes from local storage', error: e);
    }
  }

  Future<Result<void>> saveNote(Map<String, dynamic> noteData) async {
    final id =
        noteData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    dev.log('LocalDB: Saving note $id', name: 'NotesRepository');

    try {
      final note = Note(
        id: id,
        title: noteData['title'],
        textContent: noteData['text'] ?? '',
        mood: noteData['mood'] ?? '😐',
        imageUrl: noteData['imageUrl'],
        date: DateTime.tryParse(noteData['date'] ?? '') ?? DateTime.now(),
        pendingSync: noteData['pendingSync'] ?? false,
      );

      await _db.insertNote(note);
      dev.log('LocalDB: Note saved successfully', name: 'NotesRepository');
      return const Success(null);
    } catch (e) {
      dev.log('LocalDB: Error saving note: $e', name: 'NotesRepository');
      return Failure('Failed to save note locally', error: e);
    }
  }

  Future<Result<void>> deleteNote(String id) async {
    dev.log('LocalDB: Deleting note $id', name: 'NotesRepository');
    try {
      await _db.deleteNoteLocal(id);
      dev.log('LocalDB: Note deleted successfully', name: 'NotesRepository');
      return const Success(null);
    } catch (e) {
      dev.log('LocalDB: Error deleting note: $e', name: 'NotesRepository');
      return Failure('Failed to delete note locally', error: e);
    }
  }
}
