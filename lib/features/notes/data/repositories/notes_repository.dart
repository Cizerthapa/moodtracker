import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moodtrack/core/constants/app_constants.dart';

class NotesRepository {
  NotesRepository._internal();
  static final NotesRepository _instance = NotesRepository._internal();
  factory NotesRepository() => _instance;
  Future<List<Map<String, dynamic>>> getNotes() async {
    log('Preferences: Getting notes', name: 'Preferences');
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
    log('Preferences: Retrieved ${notesJson.length} notes', name: 'Preferences');
    return notesJson
        .map((n) => jsonDecode(n) as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveNote(Map<String, dynamic> note) async {
    log('Preferences: Saving note ${note['id']}', name: 'Preferences');
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
    notesJson.insert(0, jsonEncode(note));
    await prefs.setStringList(AppConstants.moodNotesPrefsKey, notesJson);
    log('Preferences: Note saved successfully', name: 'Preferences');
  }

  Future<void> deleteNote(String id) async {
    log('Preferences: Deleting note $id', name: 'Preferences');
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
    } else {
      log('Preferences: Note $id not found for deletion', name: 'Preferences');
    }
  }
}
