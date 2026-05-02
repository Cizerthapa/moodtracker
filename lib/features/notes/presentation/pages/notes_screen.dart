import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/notes/data/repositories/notes_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/services/storage_service.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/error/result.dart';
import 'add_note_screen.dart';
import 'package:moodtrack/core/widgets/unified_refresh_indicator.dart';
import 'package:moodtrack/core/services/ui_state_manager.dart';

// Mood metadata: emoji, label, card tint, accent color
final _moods = [
  {
    'emoji': '😊',
    'label': AppStrings.moodHappy,
    'tint': const Color(0xFFFFF8EC),
    'accent': const Color(0xFFD4A832),
  },
  {
    'emoji': '😌',
    'label': AppStrings.moodPeaceful,
    'tint': const Color(0xFFEEF7F0),
    'accent': const Color(0xFF6DAA7A),
  },
  {
    'emoji': '😐',
    'label': AppStrings.moodNeutral,
    'tint': const Color(0xFFF5F2ED),
    'accent': const Color(0xFF9C8878),
  },
  {
    'emoji': '😔',
    'label': AppStrings.moodSad,
    'tint': const Color(0xFFEFF3FA),
    'accent': const Color(0xFF7A8FBB),
  },
  {
    'emoji': '😡',
    'label': AppStrings.moodUpset,
    'tint': const Color(0xFFFFF0EC),
    'accent': const Color(0xFFC4635A),
  },
  {
    'emoji': '😭',
    'label': AppStrings.moodCrying,
    'tint': const Color(0xFFEFF3FA),
    'accent': const Color(0xFF6B8CB8),
  },
];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  final NotesRepository _repository = sl<NotesRepository>();
  final StorageService _storageService = sl<StorageService>();
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
      duration: const Duration(
        milliseconds: AppConstants.fadeTransitionDurationMs,
      ),
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
    final result = await _repository.getNotes();

    if (result is Success<List<Map<String, dynamic>>>) {
      if (mounted) {
        setState(() {
          _notes = result.data;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } else {
      sl<UIStateManager>().handleResult(result, retryTask: _loadNotes);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote(
    String title,
    String text,
    String emoji,
    String? imageUrl,
  ) async {
    final newNote = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'text': text,
      'mood': emoji,
      'imageUrl': imageUrl,
      'date': DateTime.now().toIso8601String(),
    };

    final result = await _repository.saveNote(newNote);
    if (result is Success) {
      HapticFeedback.mediumImpact();
      _loadNotes();
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((result as Failure).message)));
    }
  }

  Future<void> _deleteNote(String id) async {
    final result = await _repository.deleteNote(id);
    if (result is Success) {
      HapticFeedback.lightImpact();
      _loadNotes();
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((result as Failure).message)));
      // Reload to restore the item if needed, though Dismissible might need manual refresh
      _loadNotes();
    }
  }

  Map<String, dynamic> _moodMeta(String emoji) =>
      _moods.firstWhere((m) => m['emoji'] == emoji, orElse: () => _moods[2]);

  void _showAddNoteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteScreen(
          onSave: (title, text, emoji, image) async {
            String? imageUrl;
            if (image != null) {
              final path = 'notes/${DateTime.now().millisecondsSinceEpoch}.jpg';
              final uploadResult = await _storageService.uploadFile(
                file: image,
                path: path,
              );
              if (uploadResult is Success<String>) {
                imageUrl = uploadResult.data;
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text((uploadResult as Failure).message)),
                );
                return;
              }
            }
            await _saveNote(title, text, emoji, imageUrl);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) => Scaffold(
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
                          Text(
                            AppStrings.journalHeader,
                            style: TextStyle(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmBrown,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12.r,
                                color: AppColors.roseDust,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                AppStrings.journalSubHeader,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13.sp,
                                  color: AppColors.softBrown,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showAddNoteScreen();
                      },
                      child: Container(
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          color: AppColors.roseDeep,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.roseDeep.withValues(alpha: 0.3),
                              blurRadius: 14.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 8.h, 28.w, 12.h),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search your journal...",
                    hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown.withValues(alpha: 0.5),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.roseDust,
                      size: 20.r,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18.r),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.ivoryCard,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(color: AppColors.champagne),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(color: AppColors.champagne),
                    ),
                  ),
                ),
              ),

              // ── Divider ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.roseDust.withValues(alpha: 0.4),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Icon(
                        Icons.favorite,
                        size: 10.r,
                        color: AppColors.roseDust.withValues(alpha: 0.7),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.roseDust.withValues(alpha: 0.4),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Notes list ────────────────────────────────────────────
              Expanded(
                child: UnifiedRefreshIndicator(
                  onRefresh: _loadNotes,
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
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 0.6.sh,
                            child: _EmptyState(onAdd: _showAddNoteScreen),
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: RepaintBoundary(
                            child: Builder(
                              builder: (context) {
                                final filteredNotes = _searchQuery.isEmpty
                                    ? _notes
                                    : _notes
                                          .where(
                                            (n) =>
                                                (n['text'] ?? "")
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(
                                                      _searchQuery
                                                          .toLowerCase(),
                                                    ) ||
                                                (n['mood'] ?? "")
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(
                                                      _searchQuery
                                                          .toLowerCase(),
                                                    ),
                                          )
                                          .toList();

                                if (filteredNotes.isEmpty &&
                                    _searchQuery.isNotEmpty) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: 0.5.sh,
                                      child: Center(
                                        child: Text(
                                          "No notes match your search",
                                          style: TextStyle(
                                            color: AppColors.softBrown,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    20.w,
                                    4.h,
                                    20.w,
                                    100.h,
                                  ),
                                  itemCount: filteredNotes.length,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final note = filteredNotes[index];
                                    return _NoteCard(
                                      note: note,
                                      moodMeta: _moodMeta(note['mood'] ?? '😐'),
                                      onDelete: () => _deleteNote(
                                        note['id'] ?? note['date'],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
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
        margin: EdgeInsets.only(bottom: 12.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: AppColors.roseDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.roseDeep,
          size: 24.r,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 12.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(18.r),
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
                      fontStyle: FontStyle.italic,
                      fontSize: 11.sp,
                      color: AppColors.softBrown,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50.r),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 5.w),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Note Title
              if (note['title'] != null &&
                  note['title'].toString().isNotEmpty) ...[
                Text(
                  note['title'],
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmBrown,
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              // Note text
              Text(
                note['text'] ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  color: AppColors.warmBrown.withValues(alpha: 0.85),
                  height: 1.55,
                ),
              ),

              // Note Image
              if (note['imageUrl'] != null) ...[
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.network(
                    note['imageUrl'],
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return ShimmerLoading(
                        isLoading: true,
                        child: ShimmerSkeleton(height: 180.h),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
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
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📖', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 18.h),
            Text(
              AppStrings.journalEmptyTitle,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.journalEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontStyle: FontStyle.italic,
                fontSize: 14.sp,
                color: AppColors.softBrown,
                height: 1.6,
              ),
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.roseDeep,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseDeep.withValues(alpha: 0.3),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  AppStrings.writeANoteButton,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
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
