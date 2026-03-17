import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:moodtrack/core/theme/app_colors.dart';

// Mood metadata: emoji, label, card tint, icon color
const _moods = [
  {
    'emoji': '😊',
    'label': 'Happy',
    'tint': Color(0xFFFFF8EC),
    'accent': Color(0xFFD4A832),
  },
  {
    'emoji': '😌',
    'label': 'Peaceful',
    'tint': Color(0xFFEEF7F0),
    'accent': Color(0xFF6DAA7A),
  },
  {
    'emoji': '😐',
    'label': 'Neutral',
    'tint': Color(0xFFF5F2ED),
    'accent': Color(0xFF9C8878),
  },
  {
    'emoji': '😔',
    'label': 'Sad',
    'tint': Color(0xFFEFF3FA),
    'accent': Color(0xFF7A8FBB),
  },
  {
    'emoji': '😡',
    'label': 'Upset',
    'tint': Color(0xFFFFF0EC),
    'accent': Color(0xFFC4635A),
  },
  {
    'emoji': '😭',
    'label': 'Crying',
    'tint': Color(0xFFEFF3FA),
    'accent': Color(0xFF6B8CB8),
  },
];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notes = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadNotes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('mood_notes');
    if (raw != null) {
      final List<dynamic> decoded = json.decode(raw);
      setState(() {
        _notes = decoded.cast<Map<String, dynamic>>().reversed.toList();
      });
    }
    _fadeController.forward();
  }

  Future<void> _saveNote(String text, String emoji) async {
    final note = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': text,
      'mood': emoji,
      'date': DateTime.now().toIso8601String(),
    };
    final ascending = _notes.reversed.toList()..add(note);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_notes', json.encode(ascending));
    setState(() => _notes.insert(0, note));
  }

  void _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n['id'] == id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_notes', json.encode(_notes.reversed.toList()));
  }

  Map<String, dynamic> _moodMeta(String emoji) =>
      _moods.firstWhere((m) => m['emoji'] == emoji, orElse: () => _moods[2]);

  void _showAddNoteSheet() {
    final textController = TextEditingController();
    String selectedEmoji = _moods[0]['emoji'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // final meta = _moodMeta(selectedEmoji);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.champagne,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a mood, then write your heart out.',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: AppColors.softBrown,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Mood selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moods.map((m) {
                      final emoji = m['emoji'] as String;
                      final label = m['label'] as String;
                      final accent = m['accent'] as Color;
                      final isSelected = emoji == selectedEmoji;

                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? accent.withOpacity(0.5)
                                  : AppColors.champagne,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: isSelected ? 30 : 26,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 9,
                                  color: isSelected ? accent : AppColors.softBrown,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Text field
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      color: AppColors.warmBrown,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    cursorColor: AppColors.roseDeep,
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts...',
                      hintStyle: TextStyle(
                        color: AppColors.softBrown.withOpacity(0.5),
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                      ),
                      filled: true,
                      fillColor: AppColors.ivoryCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppColors.champagne, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppColors.champagne, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppColors.roseDust, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (textController.text.trim().isNotEmpty) {
                          _saveNote(textController.text.trim(), selectedEmoji);
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      label: const Text(
                        'Save Note',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Journal',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warmBrown,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: AppColors.roseDust,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'feelings, thoughts & little moments',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: AppColors.softBrown,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddNoteSheet,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.roseDeep,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.roseDeep.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.roseDust.withOpacity(0.4),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.favorite,
                      size: 10,
                      color: AppColors.roseDust.withOpacity(0.7),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.roseDust.withOpacity(0.4),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Notes list ────────────────────────────────────────────
            Expanded(
              child: _notes.isEmpty
                  ? _EmptyState(onAdd: _showAddNoteSheet)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return _NoteCard(
                            note: note,
                            moodMeta: _moodMeta(note['mood'] ?? '😐'),
                            onDelete: () => _deleteNote(note['id']),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Note Card ───────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final Map<String, dynamic> moodMeta;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.moodMeta,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(note['date']);
    final formattedDate = DateFormat('MMM d · h:mm a').format(date);
    final tint = moodMeta['tint'] as Color;
    final accent = moodMeta['accent'] as Color;
    final emoji = note['mood'] as String? ?? '😐';
    final label = moodMeta['label'] as String;

    return Dismissible(
      key: Key(note['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.roseDeep.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.roseDeep,
          size: 24,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + mood badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: AppColors.softBrown,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: accent.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Note text
              Text(
                note['text'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 15,
                  color: AppColors.warmBrown,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 18),
            const Text(
              'Your journal is empty',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Write down how you feel.\nEvery little thought matters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppColors.softBrown,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.roseDeep,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseDeep.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Write a Note',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
