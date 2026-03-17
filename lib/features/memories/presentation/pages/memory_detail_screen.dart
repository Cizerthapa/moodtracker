import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';

class MemoryDetailScreen extends StatefulWidget {
  final DocumentSnapshot doc;
  const MemoryDetailScreen({super.key, required this.doc});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late LatLng _location;
  bool _isEditing = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnim;
  final MemoriesRepository _repository = MemoriesRepository();

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _titleController = TextEditingController(text: data['title']);
    _descController = TextEditingController(text: data['description']);
    _location = LatLng(data['lat'], data['lng']);

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _heartAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _updateMemory() async {
    await _repository.updateMemory(widget.doc.id, {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
    });
    setState(() => _isEditing = false);
  }

  Future<void> _deleteMemory() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.ivoryCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            title: Text(
              AppStrings.deleteMemoryTitle,
              style: TextStyle(
                fontFamily: 'Georgia',
                color: AppColors.warmBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              AppStrings.deleteMemoryContent,
              style: TextStyle(
                color: AppColors.softBrown,
                fontSize: 14.sp,
                fontFamily: 'Georgia',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppStrings.keepIt,
                  style: TextStyle(color: AppColors.softBrown, fontFamily: 'Georgia'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppStrings.letGo,
                  style: TextStyle(
                    color: AppColors.roseDeep,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _repository.deleteMemory(widget.doc.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    double fontSize = 16,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize.sp,
        fontFamily: 'Georgia',
        color: AppColors.warmBrown,
        fontWeight: maxLines == 1 ? FontWeight.bold : FontWeight.normal,
      ),
      cursorColor: AppColors.roseDeep,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.softBrown,
          fontFamily: 'Georgia',
          fontSize: 14.sp,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.champagne, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.roseDust, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.ivoryCard,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final bool isUnique = data['isUnique'] == true;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Map Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: Padding(
              padding: EdgeInsets.all(8.r),
              child: _CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: _CircleButton(
                  icon: _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  onTap: () => _isEditing
                      ? _updateMemory()
                      : setState(() => _isEditing = true),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: _CircleButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: _deleteMemory,
                  color: AppColors.roseDeep,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Map
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _location,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _location,
                            width: 64.r,
                            height: 64.r,
                            child: ScaleTransition(
                              scale: _heartAnim,
                              child: Icon(
                                isUnique
                                    ? Icons.star_rounded
                                    : Icons.favorite_rounded,
                                color: AppColors.roseDeep,
                                size: 40.sp,
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 12.r,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Fade-to-cream at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.cream.withValues(alpha: 0),
                            AppColors.cream
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Memory Image
                  if (data['imageUrl'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: Image.network(
                        data['imageUrl'],
                        height: 250.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return ShimmerLoading(
                            isLoading: true,
                            child: ShimmerSkeleton(height: 250.h),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.champagne,
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.softBrown),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                  // Date badge / description chip
                  if (!_isEditing) ...[
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.champagne,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUnique
                                    ? Icons.star_rounded
                                    : Icons.favorite_rounded,
                                size: 14.sp,
                                color: AppColors.roseDeep,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                data['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.softBrown,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Title
                    Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Georgia',
                        color: AppColors.warmBrown,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Divider with heart
                    _HeartDivider(),
                    SizedBox(height: 20.h),

                    // Unique memory callout
                    if (isUnique) ...[
                      _SpecialMemoryCard(),
                      SizedBox(height: 20.h),
                    ],

                    // Bottom love note
                    _LoveNoteFooter(),
                    SizedBox(height: 40.h),
                  ] else ...[
                    // ── Edit mode ─────────────────────────────────────
                    _buildEditField(
                      controller: _titleController,
                      label: AppStrings.memoryTitleLabel,
                      fontSize: 22,
                      maxLines: 1,
                    ),
                    SizedBox(height: 20.h),
                    _buildEditField(
                      controller: _descController,
                      label: AppStrings.memoryDateLabel,
                      maxLines: 4,
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _updateMemory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roseDeep,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          AppStrings.saveMemory,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.warmBrown;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: 0.12),
              blurRadius: 10.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(icon, size: 18.sp, color: effectiveColor),
      ),
    );
  }
}

class _HeartDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child:
              Divider(color: AppColors.roseDust.withValues(alpha: 0.5), thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Icon(Icons.favorite, size: 14.sp, color: AppColors.roseDust),
        ),
        Expanded(
          child:
              Divider(color: AppColors.roseDust.withValues(alpha: 0.5), thickness: 1),
        ),
      ],
    );
  }
}

class _SpecialMemoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.champagne,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.roseDust.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: AppColors.roseDeep, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppStrings.specialMemoryCallout,
              style: TextStyle(
                color: AppColors.softBrown,
                fontSize: 13.sp,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoveNoteFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.champagne),
        boxShadow: [
          BoxShadow(
            color: AppColors.roseDust.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_rounded,
            color: AppColors.roseDust.withValues(alpha: 0.7),
            size: 28.sp,
          ),
          SizedBox(height: 10.h),
          Text(
            AppStrings.loveNoteText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 15.sp,
              color: AppColors.softBrown,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
