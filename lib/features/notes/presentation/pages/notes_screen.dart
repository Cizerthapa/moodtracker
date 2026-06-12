import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtrack/core/navigation/app_routes.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/core/database/local_database.dart';
import 'package:moodtrack/features/notes/data/repositories/notes_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/services/storage_service.dart';
import 'package:moodtrack/core/services/streak_service.dart';
import 'package:moodtrack/core/services/note_image_service.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:moodtrack/widget/streak_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/error/result.dart';

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

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final NotesRepository _repository = sl<NotesRepository>();
  final StorageService _storageService = sl<StorageService>();
  final NoteImageService _noteImageService = sl<NoteImageService>();
  final AppDatabase _db = sl<AppDatabase>();
  final StreakService _streakService = sl<StreakService>();
  String _searchQuery = "";
  late TextEditingController _searchController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  StreakData? _streakData;
  StreamSubscription<List<Note>>? _notesSub;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.fadeTransitionDurationMs),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _searchController = TextEditingController();
    _fadeController.forward();
    _refreshStreak();
    _notesSub = _db.watchAllNotes().listen((_) => _refreshStreak());
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStreak() async {
    final data = await _streakService.getStreakData();
    if (mounted) setState(() => _streakData = data);
  }

  Future<void> _saveNote(
    String id,
    String title,
    String text,
    String emoji,
    String? imageUrl,
  ) async {
    final newNote = {
      'id': id,
      'title': title,
      'text': text,
      'mood': emoji,
      'imageUrl': imageUrl,
      'date': DateTime.now().toIso8601String(),
    };

    final result = await _repository.saveNote(newNote);
    if (result is Success) {
      HapticFeedback.mediumImpact();
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
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((result as Failure).message)));
    }
  }

  Map<String, dynamic> _moodMeta(String emoji) =>
      _moods.firstWhere((m) => m['emoji'] == emoji, orElse: () => _moods[2]);

  void _showAddNoteScreen({Note? existingNote}) {
    context.pushNamed(
      AppRoutes.addNote,
      extra: <String, dynamic>{
        'initialTitle': existingNote?.title ?? '',
        'initialText': existingNote?.textContent ?? '',
        'initialEmoji': existingNote?.mood ?? '😐',
        // Pass back the encoded value (or plain URL for old notes) so the
        // edit screen can show the existing image via network fallback.
        'initialImage': existingNote?.imageUrl != null
            ? NoteImageService.networkUrlOf(existingNote!.imageUrl)
            : null,
        'onSave': (String title, String text, String emoji, dynamic image) async {
          final noteId =
              existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
          String? imageUrl = existingNote?.imageUrl; // keep existing encoded value

          if (image != null && image is! String) {
            // ── New image picked ─────────────────────────────────────────
            final file = image as File;
            final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

            // 1. Generate readable filename and save to Download/moodtracker/
            final fileName = await _noteImageService.generateFileName();
            await _noteImageService.saveLocally(file, fileName);

            // 2. Upload to Firebase Storage
            final storagePath = 'notes/$uid/$fileName';
            final uploadResult =
                await _storageService.uploadFile(file: file, path: storagePath);

            if (uploadResult is Success<String>) {
              final networkUrl = uploadResult.data;
              // Encode as "note1_1.jpg||https://..."
              imageUrl = NoteImageService.encode(fileName, networkUrl);

              // 3. Sync filename + URL to Firestore so reinstall can recover it
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('notes')
                    .doc(noteId)
                    .set(
                      {
                        'noteId': noteId,
                        'fileName': fileName,
                        'imageUrl': networkUrl,
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );
              } catch (_) {
                // Firestore sync failure is non-fatal; local copy is already saved.
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text((uploadResult as Failure).message)),
              );
              return;
            }
          }

          await _saveNote(noteId, title, text, emoji, imageUrl);
        },
      },
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
                          4.verticalSpace,
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12.r,
                                color: AppColors.roseDust,
                              ),
                              6.horizontalSpace,
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
                        child: Icon(Icons.edit_rounded, color: Colors.white, size: 20.r),
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
                    hintText: AppLocalizations.of(context)!.searchJournalHint,
                    hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown.withValues(alpha: 0.5),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.roseDust, size: 20.r),
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

              // ── Streak Card ───────────────────────────────────────────
              if (_streakData != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
                  child: StreakCard(data: _streakData!),
                ),

              // ── Notes list ────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Note>>(
                  stream: _db.watchAllNotes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return ListView.builder(
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
                      );
                    }

                    final notesList = snapshot.data ?? [];
                    if (notesList.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 0.6.sh,
                          child: _EmptyState(onAdd: _showAddNoteScreen),
                        ),
                      );
                    }

                    // Sort by newest first
                    notesList.sort((a, b) => b.date.compareTo(a.date));

                    final filteredNotes = _searchQuery.isEmpty
                        ? notesList
                        : notesList
                              .where(
                                (n) =>
                                    (n.textContent ?? '').toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    n.mood.toLowerCase().contains(_searchQuery.toLowerCase()),
                              )
                              .toList();

                    if (filteredNotes.isEmpty && _searchQuery.isNotEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 0.5.sh,
                          child: Center(
                            child: Text(
                              "No notes match your search",
                              style: TextStyle(color: AppColors.softBrown, fontSize: 14.sp),
                            ),
                          ),
                        ),
                      );
                    }

                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
                        itemCount: filteredNotes.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return _NoteCard(
                            note: note,
                            moodMeta: _moodMeta(note.mood),
                            onDelete: () => _deleteNote(note.id),
                            onTap: () => _showAddNoteScreen(existingNote: note),
                          );
                        },
                      ),
                    );
                  },
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
  final Note note;
  final Map<String, dynamic> moodMeta;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.moodMeta,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = note.date;
    final formattedDate = DateFormat('MMM d · h:mm a').format(date);
    final tint = moodMeta['tint'] as Color;
    final accent = moodMeta['accent'] as Color;
    final emoji = note.mood;
    final label = moodMeta['label'] as String;

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: AppColors.roseDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.roseDeep, size: 24.r),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
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
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50.r),
                        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 14.sp)),
                          5.horizontalSpace,
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
                12.verticalSpace,

                // Note Title
                if (note.title != null && note.title.toString().isNotEmpty) ...[
                  Text(
                    note.title!,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  8.verticalSpace,
                ],

                // Note text
                if (note.textContent != null && note.textContent!.isNotEmpty)
                  Text(
                    note.textContent!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      color: AppColors.warmBrown.withValues(alpha: 0.85),
                      height: 1.55,
                    ),
                  ),

                // Note Image
                if (note.imageUrl != null) ...[
                  16.verticalSpace,
                  _NoteImage(encodedImageUrl: note.imageUrl!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Note Image ──────────────────────────────────────────────────────────────
// Shows the image from local cache (Downloads/moodtracker/) when available,
// falling back to Firebase Storage download + cache on first view.

class _NoteImage extends StatelessWidget {
  final String encodedImageUrl;
  const _NoteImage({required this.encodedImageUrl});

  @override
  Widget build(BuildContext context) {
    final fileName = NoteImageService.fileNameOf(encodedImageUrl);
    final networkUrl = NoteImageService.networkUrlOf(encodedImageUrl);

    if (fileName == null || networkUrl == null) {
      // Old-format plain URL — just show network image
      return _networkImage(networkUrl ?? encodedImageUrl);
    }

    return FutureBuilder<File?>(
      future: sl<NoteImageService>().getLocalFile(fileName),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ShimmerLoading(isLoading: true, child: ShimmerSkeleton(height: 180.h));
        }
        if (snap.data != null) {
          return _localImage(snap.data!);
        }
        // File not cached yet — download from Storage and show
        return _DownloadAndShowImage(fileName: fileName, networkUrl: networkUrl);
      },
    );
  }

  Widget _localImage(File file) => ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.file(
          file,
          height: 180.h,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );

  Widget _networkImage(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.network(
          url,
          height: 180.h,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ShimmerLoading(isLoading: true, child: ShimmerSkeleton(height: 180.h));
          },
          errorBuilder: (context, _, __) => _errorPlaceholder(),
        ),
      );

  Widget _errorPlaceholder() => Container(
        height: 150.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
}

class _DownloadAndShowImage extends StatefulWidget {
  final String fileName;
  final String networkUrl;
  const _DownloadAndShowImage({required this.fileName, required this.networkUrl});

  @override
  State<_DownloadAndShowImage> createState() => _DownloadAndShowImageState();
}

class _DownloadAndShowImageState extends State<_DownloadAndShowImage> {
  File? _localFile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    final file = await sl<NoteImageService>().downloadAndCache(
      widget.networkUrl,
      widget.fileName,
    );
    if (mounted) setState(() { _localFile = file; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ShimmerLoading(isLoading: true, child: ShimmerSkeleton(height: 180.h));
    }
    if (_localFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.file(
          _localFile!,
          height: 180.h,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    // Download failed — fallback to network stream
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Image.network(
        widget.networkUrl,
        height: 180.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => Container(
          height: 150.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
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
            18.verticalSpace,
            Text(
              AppStrings.journalEmptyTitle,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            10.verticalSpace,
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
            28.verticalSpace,
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
