import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/notes/data/repositories/notes_repository.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moodtrack/core/services/storage_service.dart';
import 'dart:io';

// Mood metadata: emoji, label, card tint, accent color
final _moods = [
  {'emoji': '😊', 'label': AppStrings.moodHappy, 'tint': const Color(0xFFFFF8EC), 'accent': const Color(0xFFD4A832)},
  {'emoji': '😌', 'label': AppStrings.moodPeaceful, 'tint': const Color(0xFFEEF7F0), 'accent': const Color(0xFF6DAA7A)},
  {'emoji': '😐', 'label': AppStrings.moodNeutral, 'tint': const Color(0xFFF5F2ED), 'accent': const Color(0xFF9C8878)},
  {'emoji': '😔', 'label': AppStrings.moodSad, 'tint': const Color(0xFFEFF3FA), 'accent': const Color(0xFF7A8FBB)},
  {'emoji': '😡', 'label': AppStrings.moodUpset, 'tint': const Color(0xFFFFF0EC), 'accent': const Color(0xFFC4635A)},
  {'emoji': '😭', 'label': AppStrings.moodCrying, 'tint': const Color(0xFFEFF3FA), 'accent': const Color(0xFF6B8CB8)},
];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  final NotesRepository _repository = NotesRepository();
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String _searchQuery = "";
  late TextEditingController _searchController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.fadeTransitionDurationMs),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _searchController = TextEditingController();
    _loadNotes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await _repository.getNotes();
    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _saveNote(String text, String emoji, String? imageUrl) async {
    final newNote = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // Add id for Dismissible
      'text': text,
      'mood': emoji,
      'imageUrl': imageUrl,
      'date': DateTime.now().toIso8601String(),
    };

    await _repository.saveNote(newNote);
    _loadNotes();
  }

  Future<void> _deleteNote(String id) async {
    await _repository.deleteNote(id);
    _loadNotes();
  }

  Map<String, dynamic> _moodMeta(String emoji) =>
      _moods.firstWhere((m) => m['emoji'] == emoji, orElse: () => _moods[2]);

  void _showAddNoteSheet() {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddNoteSheet(
          onSave: (text, emoji, image) async {
            String? imageUrl;
            if (image != null) {
              final path = 'notes/${DateTime.now().millisecondsSinceEpoch}.jpg';
              imageUrl = await _storageService.uploadFile(file: image, path: path);
            }
            await _saveNote(text, emoji, imageUrl);
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
                          AppStrings.journalHeader,
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
                            const Text(
                              AppStrings.journalSubHeader,
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search your journal...",
                  hintStyle: TextStyle(
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    color: AppColors.softBrown.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.roseDust),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                  filled: true,
                  fillColor: AppColors.ivoryCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.champagne),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.champagne),
                  ),
                ),
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
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: 4,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShimmerLoading(
                          isLoading: true,
                          child: ShimmerSkeleton(
                            height: 120,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    )
                  : _notes.isEmpty
                      ? _EmptyState(onAdd: _showAddNoteSheet)
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: RepaintBoundary(
                            child: Builder(
                              builder: (context) {
                                final filteredNotes = _searchQuery.isEmpty 
                                  ? _notes 
                                  : _notes.where((n) => 
                                      (n['text'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                      (n['mood'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase())
                                    ).toList();
                                
                                if (filteredNotes.isEmpty && _searchQuery.isNotEmpty) {
                                  return Center(
                                    child: Text(
                                      "No notes match your search",
                                      style: TextStyle(fontFamily: 'Georgia', color: AppColors.softBrown),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                                  itemCount: filteredNotes.length,
                                  itemBuilder: (context, index) {
                                    final note = filteredNotes[index];
                                    return _NoteCard(
                                      note: note,
                                      moodMeta: _moodMeta(note['mood'] ?? '😐'),
                                      onDelete: () => _deleteNote(note['id'] ?? note['date']),
                                    );
                                  },
                                );
                              },
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
      key: Key(note['id'] ?? note['date']),
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

              // Note Image
              if (note['imageUrl'] != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    note['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return ShimmerLoading(
                        isLoading: true,
                        child: const ShimmerSkeleton(height: 180),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
                ),
              ],
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
              AppStrings.journalEmptyTitle,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.journalEmptySubtitle,
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
                  AppStrings.writeANoteButton,
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

class _AddNoteSheet extends StatefulWidget {
  final Function(String, String, File?) onSave;
  const _AddNoteSheet({required this.onSave});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _textController = TextEditingController();
  String _selectedEmoji = _moods[0]['emoji'] as String;
  File? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
            AppStrings.howAreYouFeeling,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.warmBrown,
            ),
          ),
          const SizedBox(height: 22),

          // Mood selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _moods.map((m) {
                final emoji = m['emoji'] as String;
                final label = m['label'] as String;
                final accent = m['accent'] as Color;
                final isSelected = emoji == _selectedEmoji;

                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? accent.withValues(alpha: 0.4) : AppColors.champagne,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: TextStyle(fontSize: isSelected ? 28 : 24)),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontFamily: 'Georgia', fontSize: 10, color: isSelected ? accent : AppColors.softBrown)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ivoryCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.champagne),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: AppColors.roseDust, size: 24),
                        const SizedBox(width: 12),
                        const Text("Add a photo", style: TextStyle(fontFamily: 'Georgia', color: AppColors.softBrown)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppStrings.writeThoughtsHint,
              filled: true,
              fillColor: AppColors.ivoryCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isSaving ? null : () async {
                if (_textController.text.trim().isNotEmpty) {
                  setState(() => _isSaving = true);
                  await widget.onSave(_textController.text.trim(), _selectedEmoji, _selectedImage);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(AppStrings.saveNoteButton, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
