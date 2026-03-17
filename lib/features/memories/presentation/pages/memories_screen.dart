import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/memories/presentation/pages/memory_detail_screen.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moodtrack/core/services/storage_service.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with SingleTickerProviderStateMixin {
  final MemoriesRepository _repository = MemoriesRepository();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _memories = [];
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
    _initData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    // 1. Try to load from cache first
    final cached = await _repository.getCachedMemories();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _memories = cached;
        _isLoading = false;
      });
      _fadeController.forward();
    }

    // 2. Then seed if empty or just wait for real-time stream
    await _seedMemoriesIfEmpty();
    
    // 3. Keep loading indicator if nothing in cache
    if (_memories.isEmpty && mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _seedMemoriesIfEmpty() async {
    // Check Firestore directly for seeding
    final snapshot = await _repository.getMemoriesStream().first;
    if (snapshot.docs.isNotEmpty) return;

    final List<Map<String, dynamic>> seeds = [
      {
        'title': 'Dinner at the Cliffside',
        'description': 'October 14, 2025',
        'lat': 40.7128,
        'lng': -74.0060,
        'isUnique': false,
      },
      {
        'title': 'The First Sunset Together',
        'description': 'September 12, 2025',
        'lat': 34.0522,
        'lng': -118.2437,
        'isUnique': true,
      },
      {
        'title': 'Stroll through Central Park',
        'description': 'August 28, 2025',
        'lat': 40.7829,
        'lng': -73.9654,
        'isUnique': false,
      },
    ];

    await _repository.seedMemories(seeds);
  }

  Future<void> _onRefresh() async {
    await _repository.fetchAndCacheMemories();
    // The StreamBuilder will handle the state update if we still use it, 
    // or we can manually reload if we switch to manual state.
    // Let's stick with StreamBuilder for real-time benefits but add RefreshIndicator.
  }

  void _showAddMemorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemorySheet(
        onSave: (title, desc, image) async {
          String? imageUrl;
          if (image != null) {
            final path = 'memories/${DateTime.now().millisecondsSinceEpoch}.jpg';
            imageUrl = await _storageService.uploadFile(file: image, path: path);
          }
          
          await _repository.addMemory(
            title: title,
            description: desc,
            lat: 27.7172, // Use current location in production
            lng: 85.3240,
            imageUrl: imageUrl,
            isUnique: false,
          );
        },
      ),
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
            _Header(onAdd: _showAddMemorySheet),
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search memories...",
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
            const _HeartDivider(),
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.all(8.0.r),
                        child: ShimmerLoading(
                          isLoading: true,
                          child: ShimmerSkeleton(
                            height: 100.h,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _repository.getMemoriesStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData && _memories.isEmpty) {
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                              itemCount: 5,
                              itemBuilder: (context, index) => Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: ShimmerLoading(
                                  isLoading: true,
                                  child: ShimmerSkeleton(
                                    height: 100.h,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.hasData ? snapshot.data!.docs : [];
                          var listToDisplay = docs.isNotEmpty 
                            ? docs.map((d) => d.data() as Map<String, dynamic>).toList()
                            : _memories;

                          if (_searchQuery.isNotEmpty) {
                            listToDisplay = listToDisplay.where((m) {
                              final title = (m['title'] ?? "").toString().toLowerCase();
                              final desc = (m['description'] ?? "").toString().toLowerCase();
                              return title.contains(_searchQuery.toLowerCase()) || 
                                     desc.contains(_searchQuery.toLowerCase());
                            }).toList();
                          }

                          if (listToDisplay.isEmpty) {
                            return _EmptyState(onAdd: _showAddMemorySheet);
                          }

                          return RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: AppColors.roseDeep,
                            backgroundColor: Colors.white,
                            child: RepaintBoundary(
                              child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
                                itemCount: listToDisplay.length,
                                itemBuilder: (context, index) {
                                  final data = listToDisplay[index];
                                  return _MemoryCard(
                                    data: data,
                                    index: index,
                                    onTap: () {
                                      if (docs.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (_, anim, __) =>
                                                MemoryDetailScreen(doc: docs[index]),
                                            transitionsBuilder: (_, anim, __, child) =>
                                                FadeTransition(
                                                  opacity: anim,
                                                  child: child,
                                                ),
                                            transitionDuration: const Duration(
                                              milliseconds: AppConstants.defaultTransitionDurationMs,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
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

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.ourStoryHeader,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 34.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmBrown,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 12.r,
                      color: AppColors.roseDust,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppStrings.ourStorySlogan,
                      style: TextStyle(
                        fontFamily: 'Georgia',
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
            onTap: onAdd,
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
                Icons.add_rounded,
                color: Colors.white,
                size: 24.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartDivider extends StatelessWidget {
  const _HeartDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

// ─── Memory Card ────────────────────────────────────────────────────────────

class _MemoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.data,
    required this.index,
    required this.onTap,
  });

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnique = widget.data['isUnique'] == true;
    final String title = widget.data['title'] ?? '';
    final String description = widget.data['description'] ?? '';

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: isUnique ? const Color(0xFFFFF0EC) : AppColors.ivoryCard,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isUnique ? AppColors.roseDeep.withValues(alpha: 0.35) : AppColors.champagne,
              width: isUnique ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnique
                    ? AppColors.roseDeep.withValues(alpha: 0.07)
                    : AppColors.warmBrown.withValues(alpha: 0.05),
                blurRadius: 12.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                // Icon dot
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: isUnique ? AppColors.roseDeep.withValues(alpha: 0.12) : AppColors.champagne,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnique ? Icons.star_rounded : Icons.favorite_rounded,
                    color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 14.w),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            fontSize: 11.sp,
                            color: isUnique ? AppColors.roseDeep : AppColors.softBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3.h),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                  size: 20.r,
                ),
              ],
            ),
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
            Icon(
              Icons.favorite_border_rounded,
              size: 52.r,
              color: AppColors.roseDust.withValues(alpha: 0.5),
            ),
            SizedBox(height: 18.h),
            Text(
              AppStrings.noMemories,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              AppStrings.noMemoriesSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
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
                  AppStrings.addMemory,
                  style: TextStyle(
                    fontFamily: 'Georgia',
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
class _AddMemorySheet extends StatefulWidget {
  final Function(String, String, File?) onSave;
  const _AddMemorySheet({required this.onSave});

  @override
  State<_AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<_AddMemorySheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28.w, 20.h, 28.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.champagne,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "New Memory",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            SizedBox(height: 20.h),
            
            // Image Picker UI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.ivoryCard,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.champagne),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: AppColors.roseDust, size: 40.r),
                          SizedBox(height: 8.h),
                          Text(
                            "Add a Photo",
                            style: TextStyle(
                              color: AppColors.softBrown,
                              fontFamily: 'Georgia',
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(color: AppColors.softBrown),
                filled: true,
                fillColor: AppColors.ivoryCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.champagne),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: "Date or Note",
                labelStyle: TextStyle(color: AppColors.softBrown),
                filled: true,
                fillColor: AppColors.ivoryCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.champagne),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : () async {
                  if (_titleController.text.isEmpty) return;
                  setState(() => _isUploading = true);
                  await widget.onSave(
                    _titleController.text,
                    _descController.text,
                    _selectedImage,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roseDeep,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: _isUploading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save Memory", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
