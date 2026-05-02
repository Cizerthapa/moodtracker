import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:moodtrack/features/memories/presentation/pages/memory_detail_screen.dart';
import 'package:moodtrack/features/memories/presentation/pages/add_memory_screen.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with SingleTickerProviderStateMixin {
  final MemoriesRepository _repository = sl<MemoriesRepository>();
  bool _isLoading = true;
  List<MemoryModel> _memories = [];
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
    final memories = await _repository.getMemoriesStream().first;
    if (memories.isNotEmpty) return;

    final List<MemoryModel> seeds = [
      const MemoryModel(
        title: 'Dinner at the Cliffside',
        description: 'October 14, 2025',
        lat: 40.7128,
        lng: -74.0060,
        isUnique: false,
      ),
      const MemoryModel(
        title: 'The First Sunset Together',
        description: 'September 12, 2025',
        lat: 34.0522,
        lng: -118.2437,
        isUnique: true,
      ),
      const MemoryModel(
        title: 'Stroll through Central Park',
        description: 'August 28, 2025',
        lat: 40.7829,
        lng: -73.9654,
        isUnique: false,
      ),
      const MemoryModel(
        title: 'Coffee & Rainy Days',
        description: 'That small cafe in Patan where we talked for hours',
        lat: 27.6744,
        lng: 85.3240,
        isUnique: false,
        herFavStory: 'I loved how you wiped the rain off my nose.',
        hisFavStory: 'Watching you smile while sipping mocha was everything.',
      ),
    ];

    // Only seed if user is sangyaa3@gmail.com
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == 'sangyaa3@gmail.com') {
      await _repository.seedMemories(seeds);
    }
  }

  Future<void> _onRefresh() async {
    await _repository.fetchAndCacheMemories();
    // The StreamBuilder will handle the state update if we still use it,
    // or we can manually reload if we switch to manual state.
    // Let's stick with StreamBuilder for real-time benefits but add RefreshIndicator.
  }

  void _showAddMemorySheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMemoryScreen(),
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
              _Header(onAdd: _showAddMemorySheet),
              // Search Bar
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 8.h, 28.w, 12.h),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: AppColors.warmBrown,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search memories...",
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
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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
                        child: StreamBuilder<List<MemoryModel>>(
                          stream: _repository.getMemoriesStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData && _memories.isEmpty) {
                              return ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  100,
                                ),
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

                            final docs = snapshot.hasData
                                ? snapshot.data!
                                : <MemoryModel>[];
                            var listToDisplay = docs.isNotEmpty
                                ? docs
                                : _memories;

                            if (_searchQuery.isNotEmpty) {
                              listToDisplay = listToDisplay.where((m) {
                                final title = m.title.toLowerCase();
                                final desc = m.description.toLowerCase();
                                return title.contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
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
                                  padding: EdgeInsets.fromLTRB(
                                    20.w,
                                    4.h,
                                    20.w,
                                    100.h,
                                  ),
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
                                              pageBuilder: (_, anim, _) =>
                                                  MemoryDetailScreen(
                                                    memory: docs[index],
                                                  ),
                                              transitionsBuilder:
                                                  (_, anim, _, child) =>
                                                      FadeTransition(
                                                        opacity: anim,
                                                        child: child,
                                                      ),
                                              transitionDuration: const Duration(
                                                milliseconds: AppConstants
                                                    .defaultTransitionDurationMs,
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
          padding: EdgeInsets.fromLTRB(28.w, 24.h, 24.w, 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.ourStoryHeader,
                      style: GoogleFonts.outfit(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warmBrown,
                        height: 1.1,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 12.r,
                          color: AppColors.roseDust,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          AppLocalizations.of(context)!.ourStorySlogan,
                          style: GoogleFonts.outfit(
                            fontStyle: FontStyle.italic,
                            fontSize: 13.sp,
                            color: AppColors.softBrown,
                            fontWeight: FontWeight.w300,
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
                  onAdd();
                },
                child: Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.roseDeep, AppColors.roseDust],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.roseDeep.withValues(alpha: 0.35),
                        blurRadius: 16.r,
                        offset: Offset(0, 6.h),
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
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.15, end: 0, duration: 500.ms);
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
  final MemoryModel data;
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
    final bool isUnique = widget.data.isUnique;
    final String title = widget.data.title;
    final String description = widget.data.description;

    return GestureDetector(
          onTapDown: (_) => _pressController.forward(),
          onTapUp: (_) {
            _pressController.reverse();
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          onTapCancel: () => _pressController.reverse(),
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnique
                      ? [
                          const Color(0xFFFFF0EC),
                          AppColors.roseDeep.withValues(alpha: 0.04),
                        ]
                      : [AppColors.ivoryCard, AppColors.ivoryCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isUnique
                      ? AppColors.roseDeep.withValues(alpha: 0.3)
                      : AppColors.champagne,
                  width: isUnique ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUnique
                        ? AppColors.roseDeep.withValues(alpha: 0.1)
                        : AppColors.warmBrown.withValues(alpha: 0.06),
                    blurRadius: 16.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    // Icon dot
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnique
                              ? [
                                  AppColors.roseDeep.withValues(alpha: 0.15),
                                  AppColors.roseDeep.withValues(alpha: 0.06),
                                ]
                              : [
                                  AppColors.champagne,
                                  AppColors.champagne.withValues(alpha: 0.6),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnique ? Icons.star_rounded : Icons.favorite_rounded,
                        color: isUnique
                            ? AppColors.roseDeep
                            : AppColors.roseDust,
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
                            style: GoogleFonts.outfit(
                              fontStyle: FontStyle.italic,
                              fontSize: 11.sp,
                              color: isUnique
                                  ? AppColors.roseDeep
                                  : AppColors.softBrown,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warmBrown,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color:
                            (isUnique ? AppColors.roseDeep : AppColors.roseDust)
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: isUnique
                            ? AppColors.roseDeep
                            : AppColors.roseDust,
                        size: 16.r,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + (widget.index * 80)),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: 100 + (widget.index * 80)),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
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
              AppLocalizations.of(context)!.noMemories,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.warmBrown,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)!.noMemoriesSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontStyle: FontStyle.italic,
                fontSize: 14.sp,
                color: AppColors.softBrown,
                height: 1.6,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onAdd();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.roseDeep, AppColors.roseDust],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseDeep.withValues(alpha: 0.35),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(context)!.addMemory,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
