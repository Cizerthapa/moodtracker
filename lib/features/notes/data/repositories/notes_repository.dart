import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class NotesRepository {
  NotesRepository._internal();
  static final NotesRepository _instance = NotesRepository._internal();
  factory NotesRepository() => _instance;
  Future<List<Map<String, dynamic>>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
    return notesJson
        .map((n) => jsonDecode(n) as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveNote(Map<String, dynamic> note) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
    notesJson.insert(0, jsonEncode(note));
    await prefs.setStringList(AppConstants.moodNotesPrefsKey, notesJson);
  }

  Future<void> deleteNote(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(AppConstants.moodNotesPrefsKey) ?? [];
    if (index >= 0 && index < notesJson.length) {
      notesJson.removeAt(index);
      await prefs.setStringList(AppConstants.moodNotesPrefsKey, notesJson);
    }
  }
}
