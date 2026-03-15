import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];

  final List<String> _moods = ['😃', '😌', '😐', '😔', '😡', '😭'];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJsonStr = prefs.getString('mood_notes');
    if (notesJsonStr != null) {
      final List<dynamic> decodedList = json.decode(notesJsonStr);
      setState(() {
        _notes = decodedList.cast<Map<String, dynamic>>().reversed.toList();
      });
    }
  }

  Future<void> _saveNote(String text, String mood) async {
    final note = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': text,
      'mood': mood,
      'date': DateTime.now().toIso8601String(),
    };

    // Keep it chronologically ascending in storage, descending in view
    final newNotesList = _notes.reversed.toList()..add(note);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_notes', json.encode(newNotesList));

    setState(() {
      _notes.insert(0, note); // add to top of view list
    });
  }

  void _deleteNote(String id) async {
    setState(() {
      _notes.removeWhere((n) => n['id'] == id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_notes', json.encode(_notes.reversed.toList()));
  }

  void _showAddNoteSheet() {
    final textController = TextEditingController();
    String selectedMood = _moods[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moods.map((mood) {
                      final isSelected = mood == selectedMood;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedMood = mood),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF97066).withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF97066)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            mood,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write down your thoughts...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97066),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (textController.text.trim().isNotEmpty) {
                          _saveNote(textController.text.trim(), selectedMood);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Save Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes & Mood')),
      body: _notes.isEmpty
          ? Center(
              child: Text(
                'No notes yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final date = DateTime.parse(note['date']);
                final formattedDate = DateFormat('MMM d, h:mm a').format(date);

                return Dismissible(
                  key: Key(note['id']),
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    color: Colors.redAccent.withOpacity(0.8),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => _deleteNote(note['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97066).withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              note['mood'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          note['text'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF97066),
        onPressed: _showAddNoteSheet,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}
