import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/core/error/result.dart';

class NotesRepository {
  NotesRepository();
  Future<Result<List<Map<String, dynamic>>>> getNotes() async {
    log('Preferences: Getting notes', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
      log('Preferences: Retrieved ${notesJson.length} notes', name: 'Preferences');
      final notes = notesJson
          .map((n) => jsonDecode(n) as Map<String, dynamic>)
          .toList();
      return Success(notes);
    } catch (e) {
      log('Preferences: Error getting notes: $e', name: 'Preferences');
      return Failure('Failed to load notes', error: e);
    }
  }

  Future<Result<void>> saveNote(Map<String, dynamic> note) async {
    log('Preferences: Saving note ${note['id']}', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
      notesJson.insert(0, jsonEncode(note));
      await prefs.setStringList(AppConstants.moodNotesPrefsKey, notesJson);
      log('Preferences: Note saved successfully', name: 'Preferences');
      return const Success(null);
    } catch (e) {
      log('Preferences: Error saving note: $e', name: 'Preferences');
      return Failure('Failed to save note', error: e);
    }
  }

  Future<Result<void>> deleteNote(String id) async {
    log('Preferences: Deleting note $id', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
      
      final index = notesJson.indexWhere((n) {
        final note = jsonDecode(n);
        return note['id'] == id || note['date'] == id; // Fallback to date if id missing
      });

      if (index != -1) {
        notesJson.removeAt(index);
        await prefs.setStringList(AppConstants.moodNotesPrefsKey, notesJson);
        log('Preferences: Note deleted successfully', name: 'Preferences');
        return const Success(null);
      } else {
        log('Preferences: Note $id not found', name: 'Preferences');
        return const Failure('Note not found');
      }
    } catch (e) {
      log('Preferences: Error deleting note: $e', name: 'Preferences');
      return Failure('Failed to delete note', error: e);
    }
  }
}
