import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/memories/presentation/pages/memory_detail_screen.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with SingleTickerProviderStateMixin {
  final MemoriesRepository _repository = MemoriesRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _memories = [];
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
    _initData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  Future<void> _addMemoryAtCurrentLocation() async {
    await _repository.addMemory(
      title: AppStrings.newMemoryTitle,
      description: AppStrings.newMemoryDescription,
      lat: 27.7172,
      lng: 85.3240,
      isUnique: false,
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
            _Header(onAdd: _addMemoryAtCurrentLocation),
            const _HeartDivider(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.roseDust,
                        strokeWidth: 2,
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _repository.getMemoriesStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData && _memories.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.roseDust,
                                strokeWidth: 2,
                              ),
                            );
                          }

                          final docs = snapshot.hasData ? snapshot.data!.docs : [];
                          final listToDisplay = docs.isNotEmpty 
                            ? docs.map((d) => d.data() as Map<String, dynamic>).toList()
                            : _memories;

                          if (listToDisplay.isEmpty) {
                            return _EmptyState(onAdd: _addMemoryAtCurrentLocation);
                          }

                          return RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: AppColors.roseDeep,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
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
                const Text(
                  AppStrings.ourStoryHeader,
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
                    const Icon(
                      Icons.favorite_rounded,
                      size: 12,
                      color: AppColors.roseDust,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      AppStrings.ourStorySlogan,
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
            onTap: onAdd,
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
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isUnique ? const Color(0xFFFFF0EC) : AppColors.ivoryCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnique ? AppColors.roseDeep.withOpacity(0.35) : AppColors.champagne,
              width: isUnique ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnique
                    ? AppColors.roseDeep.withOpacity(0.07)
                    : AppColors.warmBrown.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Icon dot
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnique ? AppColors.roseDeep.withOpacity(0.12) : AppColors.champagne,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnique ? Icons.star_rounded : Icons.favorite_rounded,
                    color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),

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
                          fontSize: 11,
                          color: isUnique ? AppColors.roseDeep : AppColors.softBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
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
                  size: 20,
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 52,
              color: AppColors.roseDust.withOpacity(0.5),
            ),
            const SizedBox(height: 18),
            const Text(
              AppStrings.noMemories,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              AppStrings.noMemoriesSubtitle,
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
                  AppStrings.addMemory,
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
